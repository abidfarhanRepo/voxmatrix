# Optimized Dockerfile for VoxMatrix Android Builder
# Uses bind mounts for faster incremental builds
# This is an alias to Dockerfile.android for compatibility

FROM eclipse-temurin:17-jdk

# Prevent prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq \
    wget \
    unzip \
    git \
    curl \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Set Flutter environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools}"

# Install Flutter SDK
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Pre-download Flutter dependencies (speeds up builds)
RUN flutter precache --android && \
    flutter doctor -v

# Download Android command line tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    unzip -q commandlinetools-linux-11076708_latest.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm commandlinetools-linux-11076708_latest.zip

# Accept Android licenses (non-interactive)
RUN yes | sdkmanager --licenses > /dev/null 2>&1

# Install required Android SDK components
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" > /dev/null 2>&1

# Set working directory
WORKDIR /workspace

# Volume for Android SDK cache
VOLUME ["/opt/android-sdk"]

# Volume for Flutter cache
VOLUME ["/opt/flutter/.pub-cache"]

# Default command (can be overridden)
CMD ["flutter", "--version"]
