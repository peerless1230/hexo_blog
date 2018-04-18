---
title: AMQP介绍
date: 2017-02-06 14:10:34
tags: 
    - Openstack与云
---

`Nova`中的每个组件都会连接消息服务器，一个组件可能是一个消息发送者（API、Scheduler），也可能是一个消息接收者（Compute、Image、conductor）。
<!-- more -->

发送消息有两种方式：同步调用(rpc.call)和异步调用(rpc.cast)。在OpenStack中，模块内部的组件通信几乎都是基于RPC，而这部分的RPC又是基于AMQP协议模型。
在`AMQP`模型中，消息的`producer`将`Message`发送给Exchange，Exchange 负责交换和路由，将消息正确地转发给相应的Queue。消息的 Consumer 从 Queue 中读取消息。这个过程是异步的，因此，Producer 和 Consumer 没有直接联系甚至可以不知道彼此的存在。Exchange 如何进行路由的呢？这便依靠 Routing Key，每个消息都有一个 routing Key，而每个 Queue 都可以通过一个 Binding 将自己所感兴趣的 Routing Key 告诉 Exchange，这样 Exchange 便可以将消息正确地转发给相应的Queue。

`OpenStack`中的`Nova`各个服务之间以松耦合的方式使用`AMQP`进行通信（RPC）。使用`AMQP`的发布/订阅模式来进行`RPC`有如下优势：
- (1) 客户端及服务端之间解耦：客户端不需要知道有哪些服务端以及服务端的地址；
- (2) 客户端与服务端之间完全的异步性：客户端的RPC不需要服务端正好在运行；
- (3) 远程调用的随机均衡：如果有多个服务端在运行，单向RPC会透明的分发到最适用的一个服务端。

![amqp_producer_consumer_model](/img/nova/amqp_producer_consumer_model.jpg)
 
由上图可以看出，交换器接收发送端应用程序的消息，通过设定的路由转发表与绑定规则将消息转发至相匹配的消息队列，消息队列继而将接收到的消息转发至对应的接收端应用程序。数据通信网络通过IP地址形成的路由表实现IP报文的转发，在AMQP环境中的通信机制也非常类似，交换器通过AMQP消息头`Header`中的路由选择关键字`Routing Key`而形成的绑定规则`Binding`来实现消息的转发，也就是说，“绑定”即连接交换机与消息队列的路由表。消息生产者发送的消息中所带有的`Routing Key`是交换器转发的判断因素，相当于AMQP中的“IP地址”，交换器获取消息之后提取`Routing Key`触发路由，通过绑定规则将消息转发至相应队列，消息消费者最后从队列中获取消息。AMQP定义三种不同类型的交换器：广播式交换器`Fanout Exchange`、直接式交换器`Direct Exchange`和主题式交换器`Topic Exchange`，三种交换器实现的绑定规则也有所不同。

### 广播式交换器类型（fanout）
该类交换器不分析所接收到消息中的`Routing Key`，默认将消息转发到所有与该交换器绑定的队列中去。广播式交换器转发效率最高，但是安全性较低，消费者应用程序可能会获取本不属于自己的消息。
广播交换器是最简单的一种类型，就像我们从字面上理解到的一样，它把所有接受到的消息广播到所有它所知道的队列中去，不论消息的关键字是什么，消息都会被路由到和该交换器绑定的队列中去。
它的工作方式如下图所示：

![amqp_fanout_model](/img/nova/amqp_fanout_model.jpg)


### 直接式交换器类型（direct）
此类交换器需要精确匹配`Routing Key`与`BindingKey`，如消息的`Routing Key = Cloud`，那么该条消息只能被转发至`Binding Key = Cloud`的消息队列中去。直接式交换器的转发效率较高，安全性较好，但是缺乏灵活性，系统配置量较大。
相对广播交换器来说，直接交换器可以给我们带来更多的灵活性。直接交换器的路由算法很简单——一个消息的`routing_key`完全匹配一个队列的 `binding_key`，就将这个消息路由到该队列。绑定的关键字将队列和交换器绑定到一起。当消息的`routing_key`和多个`routing_key`匹配时，消息会被发送到多个队列中。
我们通过下图来说明直接交换器的工作方式：

![amqp_direct_model](/img/nova/amqp_direct_model.jpg)

如图：Q1，Q2两个队列绑定到了直接交换器X上，Q1的binding_key是`orange`，Q2有两个绑定，一个binding_key是`black`，另一个binding_key是`green`。在这样的关系下，一个带有 `orange` routing_key的消息发送到X交换器之后将会被X路由到队列Q1，一个带有 `black` 或者 `green`routing_key的消息发送到X交换器之后将会被路由到Q2。而所有其他消息将会被丢失掉。
 
### 主题式交换器（Topic Exchange）
此类交换器通过消息的Routing Key与Binding Key的模式匹配，将消息转发至所有符合绑定规则的队列中。Binding Key支持通配符，其中`*`匹配一个词组，`#`匹配多个词组（包括零个）。例如，`Binding Key=“*.nova.#”`可转发`Routing Key=“OpenStack.nova.api”`、`“OpenStack.nova.compute”`以及`“OpenStack.nova”`的消息，但是对于`Routing Key=“nova.api”`的消息是无法匹配的。

![amqp_topic_model](/img/nova/amqp_topic_model.jpg)
 
这里的`routing_key`可以使用一种类似正则表达式的形式来进行通配，但是特殊字符只能是`*`和`#`，`*`代表一个单词，`#`代表0个或是多个单词。这样发送过来的消息如果符合某个queue的routing_key定义的规则，那么就会转发给这个queue。
 
在Nova中主要实现`Direct`和`Topic`两种交换器的应用，在系统初始化的过程中，各个模块基于`Direct`交换器针对每一条系统消息自动生成多个队列注入`RabbitMQ`服务器中，依据`Direct`交换器的特性要求，`Binding Key=“MSG-ID”`的消息队列只会存储与转发`Routing Key=“MSG-ID”`的消息。同时，各个模块作为消息消费者基于`Topic`交换器自动生成两个队列注入`RabbitMQ`服务器中。

### Nova RPC调用机制（基于RabbitMQ）
下图说明了Nova RPC机制的主要结成部分（以使用RabbitMQ为例）。从调用关系上来说，Nova服务要么以调用方（Invoker：API，Scheduler）角色来使用消息队列，要么以服务方（Worker：Compute，Volume，Network）角色来使用消息队列。调用方通过rpc.call和rpc.cast发送消息；服务方从消息队列接收消息，并对rpc.call请求做出响应。
从生命周期上来说，`TopicPublisher`，`DirectConsumer`，`DirectPublisher`三部分是在`rpc.call`发起的时候创建的；而`TopicConsumer`是Nova的各个服务在启动时创建，并在服务结束时销毁。Nova中每一个服务在启动时会创建两个`TopicConsumer`：一个以`NODE-TYPE`为交换器`Exchange Key`，一个以`NODE-TYPE.HOST`为交换器。

![openstack_rabbitmq_architecture](/img/nova/openstack_rabbitmq_architecture.png)

#### 1、rpc.call调用流程（比较少用到）
- 1). 初始化一个`TopicPublisher`，发送消息到消息队列；在发送消息之前，初始化一个`DirectConsumer`（以消息ID为交换器的名称），用于等待响应消息；
- 2). 消息被交换器分发到`NODE-TYPE.HOST`消息队列（下图中的topic.host），并被相应服务结点（根据host确定）的`TopicConsumer`获取到；
- 3). 服务结点根据消息内容（调用函数及参数）调用相应服务；调用完成后，初始化一个`DirectPublisher`，并根据消息ID将响应消息发送到相应的消息队列；
- 4). 响应消息被调用方的`DirectConsumer`获取到，调用完成。

![openstack_rabbitmq_rpc_call](/img/nova/openstack_rabbitmq_rpc_call.png)

注意：图中红色箭头的数据流走向

### 2、rpc.cast调用流程（经常会被用到）
- 1). 初始化一个`TopicPublisher`，并将消息发送到消息队列；
- 2). 消息被交换器分发到`NODE-TYPE`消息队列（下图中的topic），并被相应服务的结点`TopicConsumer`获取到，然后根据消息内容调用相应服务完成调用。

![openstack_rabbitmq_rpc_cast](/img/nova/openstack_rabbitmq_rpc_cast.png)

注意：图中红色箭头的数据流走向
