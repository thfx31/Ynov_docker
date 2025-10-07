# Start from the official Jenkins image
FROM jenkins/jenkins:2.430-jdk21

# Switch to root to install packages
USER root

# Install basic tools (git, docker CLI, etc.)
RUN apt-get update && \
    apt-get install -y git curl docker.io && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Allow Jenkins user to use Docker socket if mounted
RUN usermod -aG docker jenkins

# Set Jenkins home
ENV JENKINS_HOME=/var/jenkins_home

# Switch back to the Jenkins user
USER jenkins

# Expose default ports (UI + JNLP)
EXPOSE 8080 50000
