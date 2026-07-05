FROM osrf/ros:humble-desktop

WORKDIR /ros_ws

# Copy the package into the workspace
COPY aido_telemetry/ src/aido_telemetry/

# Build the package — this compiles TelemetryMsg.msg into Python classes
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
    colcon build --packages-select aido_telemetry"

# Source ROS 2 and our workspace on every shell
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /ros_ws/install/setup.bash" >> /root/.bashrc