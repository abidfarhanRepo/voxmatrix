FROM ubuntu:24.04

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    xz-utils \
    git \
    openjdk-17-jdk \
    lib32stdc++6 \
    lib32z1 \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Download and setup Android SDK
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /opt/android-sdk/ && \
    mkdir -p /opt/android-sdk/cmdline-tools/latest && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest/ 2>/dev/null || true && \
    rm /tmp/cmdline-tools.zip

# Accept Android licenses
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
RUN yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses || true

# Setup Flutter
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -O /tmp/flutter.tar.xz && \
    tar -xf /tmp/flutter.tar.xz -C /opt && \
    rm /tmp/flutter.tar.xz

ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

# Fix git ownership issue
RUN git config --global --add safe.directory /opt/flutter

# Setup working directory
WORKDIR /app
COPY app /app

# Build APK - set ANDROID_HOME inline
RUN export ANDROID_HOME=/opt/android-sdk && \
    export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH && \
    flutter pub get && \
    flutter build apk --debug

# Output
CMD ["ls", "-la", "build/app/outputs/flutter-apk/"]
