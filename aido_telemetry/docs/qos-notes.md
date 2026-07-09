# QoS Notes — aido_telemetry

## Configuration 

In the `aido_telemetry` folder, both `publisher.py` and `subscriber.py` call `create_publisher`/`create_subscription` with a plain integer "10", which uses rclpy's "default QoS profile" (here, QoS or Quality of Service refers to a set of configurable policies that we can set for the publisher and subscriber nodes on the network, to tell DDS how to handle delivery). Do note that this has been implicitly set according to the QoS standards for rclpy: 

- **Reliability:** RELIABLE
- **History:** KEEP_LAST
- **Depth:** 10

## Why RELIABLE (continuous retries) over BEST_EFFORT (fire + forget)?

Telemetry (position, battery, heading) represents a current robot's state that a human or another system can use to gauge the present situation of the user and act accordingly. Losing a message under BEST_EFFORT means a stale reading could be mistaken for current state with no way to know it was dropped. RELIABLE guarantees delivery (with retries) at the cost of some latency under packet loss, which is, in my opinion, an acceptable trade for a 10Hz stream where a small delay doesn't matter much.

Note that BEST_EFFORT would be the right call for something like a raw video/image stream, where a dropped frame is invisible to a human watching a continuous feed, and retrying a stale frame is worse than just moving on to the next one.

## Why KEEP_LAST with depth 10

KEEP_LAST(10) means the publisher buffers the last 10 messages for any late-joining subscriber, rather than KEEP_ALL, which has unbounded memory growth. At 10Hz, 10 messages is one second of history, which gives enough telemetry history for the user to gauge the conditions from context while also not being overwhelmed by a humongous stream of events.

## A concrete case where BEST_EFFORT would lose data I cared about

If the rover's battery telemetry used BEST_EFFORT over a lossy WiFi link (the kind of link an outdoor patrol robot would realistically use), a dropped low-battery warning at like 4% could mean the operator dashboard never shows the drop from 5%
to 4%: it just sees the next message minutes later. If that message happens to be the one right before the battery dies mid-patrol, the human never got the chance to act on it, even though the "pattern" sounds trivial.