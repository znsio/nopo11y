# Istio Global Rate Limiting Helm Chart

This Helm chart provides a mechanism to configure and deploy global rate limiting in Istio for services using sidecar and ambient mode. It dynamically creates the necessary ConfigMaps and EnvoyFilters for each service based on the provided configuration. Additionally, the chart deploys a [Rate Limit Service](https://github.com/envoyproxy/ratelimit?tab=readme-ov-file#overview) with Redis as a caching layer.

## Features

- Supports both Sidecar and Ambient mode
- Namespace-level configuration.
- Service-specific rate limiting.
- Support for multiple [descriptors](https://github.com/envoyproxy/ratelimit?tab=readme-ov-file#descriptor-list-definition) and [actions](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#config-route-v3-ratelimit-action) per service.
- Automated creation of ConfigMaps and EnvoyFilters.
- Deployment of a Rate Limit Service with Redis for caching.

## Prerequisites

1. Kubernetes cluster with Istio installed.
2. Waypoint proxies enabled in Istio if Istio mode is ambient.
3. Helm installed.

## Installation

1. Clone this repository which contains the Helm chart.
2. Navigate to the Helm cloned repository:
   ```bash
   cd istio-rate-limiter
   ```
3. Install the Helm chart with a custom `values.yaml` file:
   ```bash
   helm install istio-rate-limiter . -f values.yaml
   ```

## Configuration

The chart accepts configuration for mode, namespaces, waypoint proxy selectors (if Istio mode is ambient), services, workload selector (if Istio mode in sidecar), descriptors, and actions. Below is an example of the `values.yaml` structure for both sidecar and ambient mode:

**Sidecar Mode**:
```yaml
mode: sidecar
namespaces:
- name: "components"
  services:
  - name: "service-a"
    domain: "service-a-limiter"
    workloadSelector:
      app: service-a
    descriptors:
      - key: "user_id"
        value: "user123"
        rateLimit:
          unit: "second"
          requestsPerUnit: 10
      - key: "path"
        value: "/api/data"
        rateLimit:
          unit: "minute"
          requestsPerUnit: 100
    actions:
      - header_name: "user_id"
        descriptor_key: "user_id"
      - request_headers:
          header_name: ":path"
          descriptor_key: "path"
- name: "canvas"  
  services:
  - name: "service-b"
    domain: "service-b-limiter"
    workloadSelector:
      app: service-b
    descriptors:
      - key: "client_id"
        value: "client_abc"
        rateLimit:
          unit: "minute"
          requestsPerUnit: 50
    actions:
      - header_name: "client_id"
        descriptor_key: "client_id"
```


**Ambient Mode**:
```yaml
mode: ambient
namespaces:
- name: "components"
  waypointProxySelector:
    labels:
      istio.io/gateway-name: "waypoint-proxy"  
  services:
  - name: "service-a"
    domain: "service-a-limiter"
    port: 8080
    descriptors:
      - key: "user_id"
        value: "user123"
        rateLimit:
          unit: "second"
          requestsPerUnit: 10
      - key: "path"
        value: "/api/data"
        rateLimit:
          unit: "minute"
          requestsPerUnit: 100
    actions:
      - header_name: "user_id"
        descriptor_key: "user_id"
      - request_headers:
          header_name: ":path"
          descriptor_key: "path"
- name: "canvas"
  waypointProxySelector:
    labels:
      istio.io/gateway-name: "waypoint-proxy"  
  services:
  - name: "service-b"
    domain: "service-b-limiter"
    port: 8081
    descriptors:
      - key: "client_id"
        value: "client_abc"
        rateLimit:
          unit: "minute"
          requestsPerUnit: 50
    actions:
      - header_name: "client_id"
        descriptor_key: "client_id"
```

### Parameters

#### Mode configuration
- `mode`: (Required)Istio mode, either sidecar or ambeint default is sidecar

#### Namespace Configuration
- `name`: (Required)Name of the namespace.
- `waypointProxySelector`: (Optional in both sidecar and ambient mode)Labels to identify the waypoint proxy for the namespace, if not provided it will use default label `name: <namespace>-waypoint`.

#### Service Configuration
- `name`: (Required)Name of the service.
- `domain`: (Optional in both sidecar and ambient)Domain for the rate limiter, if not provided the defaul domian `<service-name>-limiter` would be added in config.
- `port`: (Optional in sidecar mode, required in ambeint mode)Port for the service.
- `workloadSelector1`: (Required in sidecar mode, optional in ambient mode)Pod labels to identify the Istio sidecar proxy workload
- `descriptors`: (Required)List of rate limiting descriptors.
  - `key`: The key for the descriptor.
  - `value`: The value for the descriptor.
  - `rateLimit`: Rate limiting details.
    - `unit`: Time unit (`second`, `minute`, etc.).
    - `requestsPerUnit`: Allowed requests per unit.
- `actions`: (Required)List of actions corresponding to descriptors.
  - `header_name`: HTTP header name to map to the descriptor key.
  - `request_headers`: Map a specific header to a descriptor key.

### Rate Limit Service Configuration
The chart deploys a Rate Limit Service that works alongside Redis for caching rate limiting data. The following parameters can be customized:

- `rateLimitService.image`: Docker image for the Rate Limit Service.
- `redis.image`: Docker image for Redis.

Below is an example of how to configure the Rate Limit Service in `values.yaml`:

```yaml
rateLimitService:
  image: "envoyproxy/ratelimit:latest"

redis:
  image: "redis:alpine"
```

### Example Values

Below is an example of a complete `values.yaml` configuration for both sidecar and ambient mode:

**Sidecar Mode**:
```yaml
mode: sidecar
namespaces:
- name: "example-namespace"  
  services:
  - name: "example-service"
    domain: "example-service-limiter"
    workloadSelector:
      app: example-service
    descriptors:
      - key: "example_key"
        value: "example_value"
        rateLimit:
          unit: "minute"
          requestsPerUnit: 50
    actions:
      - header_name: "example_header"
        descriptor_key: "example_key"
rateLimitService:
  image: "envoyproxy/ratelimit:latest"

redis:
  image: "redis:alpine"
```

**Ambient Mode**:
```yaml
mode: ambient
namespaces:
- name: "example-namespace"
waypointProxySelector:
    labels:
      istio.io/gateway-name: "example-waypoint-proxy"
  services:
  - name: "example-service"
    domain: "example-service-limiter"
    port: 8080
    descriptors:
      - key: "example_key"
        value: "example_value"
        rateLimit:
          unit: "minute"
          requestsPerUnit: 50
    actions:
      - header_name: "example_header"
        descriptor_key: "example_key"
rateLimitService:
  image: "envoyproxy/ratelimit:latest"

redis:
  image: "redis:alpine"
```

## Resources Created

For each service:
1. **ConfigMap**: Contains the rate limiting configuration.
2. **EnvoyFilter**: Applies the rate limiting rules to the Sidecar or Waypoint Proxy.

Additionally:
- **Rate Limit Service**: The service that enforces rate limits using Redis as a backend.
- **Redis Deployment**: A Redis instance for caching rate limiting data (if not using an external Redis).

## Uninstallation

To uninstall the Helm chart:
```bash
helm uninstall istio-rate-limiter
```