# Introduction

**Unlock the Future of Operations with Nopo11y**

Welcome to NopO11y, we provide you a set of Helm charts that can be used to install and configure observability in your kubernetes cluster.

Our aim is to build a cutting-edge platform that allows you manage and monitor your IT infrastructure using the NoOps principles. Combining the power of NoOps with unparalleled observability, NopO11y empowers your development teams to focus on innovation while we handle the rest.

## **Why NopO11y?**

*   **Seamless NoOps Experience**: Automate your operations and eliminate the need for manual intervention. Nopo11y ensures your infrastructure is always up and running, allowing your team to concentrate on delivering value.
    
*   **Enhanced Observability**: Gain deep insights into your system’s health and performance with advanced monitoring and logging. Our platform provides comprehensive visibility, enabling proactive issue resolution and optimal performance tuning.
    
*   **Scalability and Flexibility**: Built for modern, dynamic environments, Nopo11y scales effortlessly with your needs. Whether you're running in the cloud, on-premises, or in a hybrid setup, our platform adapts to your requirements.
    
*   **User-Friendly Interface**: With an intuitive dashboard and easy-to-use tools, Nopo11y makes it simple to manage and visualize your operations. No steep learning curves, just seamless functionality.
    
*   **Security and Reliability**: Trust in our robust, secure infrastructure that ensures your data and operations are protected. Nopo11y’s resilient design guarantees high availability and minimal downtime.

**Nopo11y - NoOps, Total Observability, Infinite Possibilities.**

# Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add znsio https://znsio.github.io/nopo11y

If you had already added this repo earlier, run following command to retrieve the latest versions of the packages,

    helm repo update

You can then run following command to see the available charts,

    helm search repo znsio

To install the <chart-name> chart:

    helm install my-<chart-name> znsio/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>
