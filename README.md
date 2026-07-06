# Aido (Telemetry)

This is a small ROS 2 Humble Python package that simulates outdoor patrol telemetry for InGen Dynamics' product Aido Rover. It publishes a custom `TelemetryMsg` (position, battery, heading, timestamp) at 10Hz, logs it via a subscriber, and exposes a
`/set_patrol_speed` service; i.e, the standard ROS 2 patterns (topics, custom messages, services) applied to a plausible robotics use case.

## How to run it

1. Clone the repo

```bash
git clone https://github.com/ShaunTheSheep25/aido-telemetry.git
cd aido-telemetry
```

2. Build the publisher, subscriber and service docker images, and run them in the terminal:

```bash
docker-compose up --build publisher subscriber service
```

Each service runs in its own container on `network_mode: host` with a shared `ROS_DOMAIN_ID`, so they discover each other over DDS despite being separate containers. You should see the publisher logging `Published - heading: X° battery: 85.0%` every 100ms, and the subscriber logging the same data as `Received - ...`.

## How to test it

I've not implemented an automated test suite for this package, however, one can carry out manual verification using the below commands to ensure proper working:

```bash
docker exec -it aido_publisher bash -c "source /opt/ros/humble/setup.bash && source /ros_ws/install/setup.bash && ros2 topic hz /aido/telemetry --window 5" # Confirms the topic is alive and typed correctly

docker exec -it aido_service bash -c "source /opt/ros/humble/setup.bash && source /ros_ws/install/setup.bash && ros2 service call /set_patrol_speed aido_telemetry/srv/SetPatrolSpeed \"{speed: 1.5}\"" # Calls the service directly
```

Expect `average rate: 10.00` from the first, and `response: aido_telemetry.srv.SetPatrolSpeed_Response(ok=True)` from the second.

## Known limitations + How I'd fix them

- `position` is a single `float32` (currently hardcoded to a latitude-like value), not a real 2D/3D coordinate — a real rover would need at least x/y or lat/lon, so I'd probably give `position` a real structure (`geometry_msgs/Point` or a custom `x`/`y`/`z`), and add a second synthetic field like `gps_fix_quality` to make the message shape more representative of a real rover.
- No automated tests; verification is manual `ros2 topic`/`ros2 service` CLI calls as shown above.
- No CI pipeline — lint/build/test only run locally, not on push. Thus, I'd add a GitHub Actions workflow that at minimum runs `colcon build` in CI so a broken build is caught on push, not just locally.
- QoS is left at rclpy's implicit default rather than an explicitly constructed `QoSProfile` (documented and justified in `docs/qos-notes.md`, but stating it explicitly in code would be more robust than relying on the default holding).
- Discovered during development: FastRTPS's shared-memory transport can silently fail to deliver data between Docker containers on the same host, even though discovery (`ros2 topic list`) works — worked around with a UDP-only FastRTPS profile; see `docs/known-issues.md`.
- I'd maybe also add a couple of `launch_testing`-based integration tests that spin up the publisher and subscriber together and assert a message round-trips correctly.