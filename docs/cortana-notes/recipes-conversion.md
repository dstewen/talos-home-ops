

Here are all 37 llmkube Model + InferenceService CRD pairs with:
- `count` instead of `tensorParallelism`
- `$schema` annotations on both Model and InferenceService
- `probeOverrides` on all InferenceServices
- `eugr/spark-vllm-b12x:latest` for B12X recipes
- No `--distributed-executor-backend ray`
- All original parameters preserved

---

## Qwen3.6 Family (5 recipes)

### 1. qwen3.6-35b-a3b-fp8.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.6-35B-A3B-FP8
# Recipe: qwen3.6-35b-a3b-fp8.yaml
# Single-node TP=2, FP8 KV cache, fastsafetensors
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen36-35b-a3b-fp8
spec:
  source: hf://Qwen/Qwen3.6-35B-A3B-FP8
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving for Qwen3.6-35B-A3B-FP8
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen36-35b-a3b-fp8
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen36-35b-a3b-fp8
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 2
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "2000m"
    memory: "32Gi"
    nvidia.com/gpu: "2"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_xml
    - --reasoning-parser qwen3
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --tensor-parallel-size 2
    - --enable-chunked-prefill
    - --async-scheduling
  env:
    - name: VLLM_MARLIN_USE_ATOMIC_ADD
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 2. qwen3.6-35b-a3b-fp8-dflash.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.6-35B-A3B-FP8 + DFlash draft
# Recipe: qwen3.6-35b-a3b-fp8-dflash.yaml
# Single-node TP=2, FP8 KV cache, DFlash speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen36-35b-a3b-fp8-dflash
spec:
  source: hf://Qwen/Qwen3.6-35B-A3B-FP8
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with DFlash speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen36-35b-a3b-fp8-dflash
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen36-35b-a3b-fp8-dflash
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 2
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "2000m"
    memory: "32Gi"
    nvidia.com/gpu: "2"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_xml
    - --reasoning-parser qwen3
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-chunked-prefill
    - --async-scheduling
    - --speculative-config '{"method":"dflash","model":"Qwen/Qwen3.6-35B-A3B-DFlash2","num_speculative_tokens":8}'
  env:
    - name: VLLM_MARLIN_USE_ATOMIC_ADD
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 3. qwen3.6-35b-a3b-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.6-35B-A3B-NVFP4
# Recipe: qwen3.6-35b-a3b-nvfp4.yaml
# Single-node TP=2, NVFP4 quantization, MTP speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen36-35b-a3b-nvfp4
spec:
  source: hf://Qwen/Qwen3.6-35B-A3B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + MTP
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen36-35b-a3b-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen36-35b-a3b-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 2
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "2000m"
    memory: "32Gi"
    nvidia.com/gpu: "2"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_xml
    - --reasoning-parser qwen3
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --speculative-config '{"method":"mtp","num_speculative_tokens":4}'
  env:
    - name: VLLM_MARLIN_USE_ATOMIC_ADD
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 4. qwen3.6-35b-a3b-nvfp4-no-mtp.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.6-35B-A3B-NVFP4 (no MTP)
# Recipe: qwen3.6-35b-a3b-nvfp4-no-mtp.yaml
# Single-node TP=2, NVFP4 quantization, no speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen36-35b-a3b-nvfp4-no-mtp
spec:
  source: hf://Qwen/Qwen3.6-35B-A3B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4, no MTP
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen36-35b-a3b-nvfp4-no-mtp
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen36-35b-a3b-nvfp4-no-mtp
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 2
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "2000m"
    memory: "32Gi"
    nvidia.com/gpu: "2"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_xml
    - --reasoning-parser qwen3
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  env:
    - name: VLLM_MARLIN_USE_ATOMIC_ADD
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 5. qwen3.6-35b-a3b-nvfp4-cluster.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.6-35B-A3B-NVFP4 (cluster)
# Recipe: qwen3.6-35b-a3b-nvfp4-cluster.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen36-35b-a3b-nvfp4-cluster
spec:
  source: hf://Qwen/Qwen3.6-35B-A3B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4, multi-node TP=2
# NOTE: Requires spark1/spark2 fabric interfaces configured and RDMA device plugin
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen36-35b-a3b-nvfp4-cluster
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen36-35b-a3b-nvfp4-cluster
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_xml
    - --reasoning-parser qwen3
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  env:
    - name: VLLM_MARLIN_USE_ATOMIC_ADD
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## Qwen3.5 Family (4 recipes)

### 6. qwen3.5-35b-a3b-fp8.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.5-35B-A3B-FP8
# Recipe: qwen3.5-35b-a3b-fp8.yaml
# Single-node TP=1, FP8 format
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen35-35b-a3b-fp8
spec:
  source: hf://Qwen/Qwen3.5-35B-A3B-FP8
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving for Qwen3.5-35B-A3B-FP8
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen35-35b-a3b-fp8
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen35-35b-a3b-fp8
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_xml
    - --reasoning-parser qwen3
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  env:
    - name: VLLM_MARLIN_USE_ATOMIC_ADD
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 7. qwen3.5-122b-fp8.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Qwen/Qwen3.5-122B-FP8
# Recipe: qwen3.5-122b-fp8.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen35-122b-fp8
spec:
  source: hf://Qwen/Qwen3.5-122B-FP8
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen35-122b-fp8
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen35-122b-fp8
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 8. qwen3.5-122b-int4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Intel/Qwen3.5-122B-A10B-int4-AutoRound
# Recipe: qwen3.5-122b-int4-autoround.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen35-122b-int4
spec:
  source: hf://Intel/Qwen3.5-122B-A10B-int4-AutoRound
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen35-122b-int4
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen35-122b-int4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 9. qwen3.5-397b-int4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Intel/Qwen3.5-397B-A17B-int4-AutoRound
# Recipe: qwen3.5-397b-int4-autoround.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
# NOTE: Uses kv-cache-prealloc-cleanup mod, gpu-mem-util-gb mod
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen35-397b-int4
spec:
  source: hf://Intel/Qwen3.5-397B-A17B-int4-AutoRound
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen35-397b-int4
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen35-397b-int4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "2000m"
    memory: "110Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.85
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  env:
    - name: VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS
      value: "0"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## Qwen3.8 Family (5 recipes)

### 10. qwen3.8-27b-nvfp4-dflash2.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/Qwen3.8-27B-NVFP4 + DFlash2 draft
# Recipe: qwen3.8-27b-nvfp4-dflash2.yaml
# Single-node TP=1, NVFP4 + DFlash2 speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen38-27b-nvfp4-dflash2
spec:
  source: hf://nvidia/Qwen3.8-27B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + DFlash2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen38-27b-nvfp4-dflash2
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen38-27b-nvfp4-dflash2
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 16384
  parallelSlots: 1
  batchSize: 16384
  uBatchSize: 16384
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 16384
    - --max-num-seqs 8
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format instanttensor
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --reasoning-parser qwen3
    - --tool-call-parser qwen3_xml
    - --enable-auto-tool-choice
    - --speculative-config '{"method":"dflash","model":"z-lab/Qwen3.8-27B-DFlash2","num_speculative_tokens":8,"draft_tensor_parallel_size":1}'
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 11. qwen3.8-flash-next-fp4-local.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/Qwen3.8-Flash-Next-FP4-Local
# Recipe: qwen3.8-flash-next-nvfp4-solo.yaml
# B12X-optimized single-node serving with PLE disk offload
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen38-flash-next-fp4-local
spec:
  source: hf://nvidia/Qwen3.8-Flash-Next-FP4-Local
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, B12X image + all B12X env vars
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen38-flash-next-fp4-local
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen38-flash-next-fp4-local
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm-b12x:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  blocksize: 16
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --tensor-parallel-size 1
    - --pipeline-parallel-size 1
    - --mamba-cache-mode align
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --dtype bfloat16
    - --kv-cache-dtype fp8
    - --quantization modelopt_mixed
    - --block-size 16
    - --load-format b12x
    - --max-model-len 262144
    - --max-num-seqs 8
    - --max-num-batched-tokens 4096
    - --speculative-config '{"method":"mtp","num_speculative_tokens":4}'
    - --gdn-decode-kernel b12x
    - --linear-backend b12x
    - --moe-backend b12x
    - --no-enable-flashinfer-autotune
    - --mm-encoder-tp-mode data
    - --reasoning-parser qwen3
    - --tool-call-parser qwen3_xml
    - --enable-auto-tool-choice
    - --compilation-config '{"pass_config":{"fuse_act_quant":true}}'
    - --gpu-memory-utilization 0.8
  env:
    - name: PYTORCH_ALLOC_CONF
      value: "per_process_memory_fraction:0.8"
    - name: VLLM_PLE_TABLE_MEMORY
      value: "disk"
    - name: B12X_DISK_BACKEND
      value: "io_uring"
    - name: CUTE_DSL_ARCH
      value: "sm_121a"
    - name: SAFETENSORS_FAST_GPU
      value: "1"
    - name: VLLM_WORKER_MULTIPROC_METHOD
      value: "spawn"
    - name: VLLM_SSM_CONV_STATE_LAYOUT
      value: "DS"
    - name: VLLM_USE_AOT_COMPILE
      value: "1"
    - name: VLLM_USE_MEGA_AOT_ARTIFACT
      value: "1"
    - name: VLLM_USE_V2_MODEL_RUNNER
      value: "1"
    - name: B12X_POLICY_MODE
      value: "auto"
    - name: VLLM_MXFP8_LM_HEAD
      value: "1"
    - name: VLLM_B12X_MOE_FP4_LAYER_MAX_INPUT_SCALE
      value: "w13"
    - name: VLLM_B12X_MOE_FP4_FORCE_A16
      value: "1"
    - name: B12X_W4A16_A4_PREFILL
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 12. qwen3.8-flash-next-fp4-cluster.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/Qwen3.8-Flash-Next-FP4-Local (cluster)
# Recipe: qwen3.8-flash-next-nvfp4-cluster.yaml
# B12X-optimized cluster serving, TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen38-flash-next-fp4-cluster
spec:
  source: hf://nvidia/Qwen3.8-Flash-Next-FP4-Local
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, B12X image, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen38-flash-next-fp4-cluster
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen38-flash-next-fp4-cluster
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm-b12x:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  blocksize: 16
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --mamba-cache-mode align
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --dtype bfloat16
    - --kv-cache-dtype fp8
    - --quantization modelopt_mixed
    - --block-size 16
    - --load-format b12x
    - --max-model-len 262144
    - --max-num-seqs 8
    - --max-num-batched-tokens 4096
    - --speculative-config '{"method":"mtp","num_speculative_tokens":4}'
    - --gdn-decode-kernel b12x
    - --linear-backend b12x
    - --moe-backend b12x
    - --no-enable-flashinfer-autotune
    - --mm-encoder-tp-mode data
    - --reasoning-parser qwen3
    - --tool-call-parser qwen3_xml
    - --enable-auto-tool-choice
    - --compilation-config '{"pass_config":{"fuse_act_quant":true}}'
    - --gpu-memory-utilization 0.8
    - --tensor-parallel-size 2
    - --additional-config '{"ple_table_memory":"device"}'
  env:
    - name: PYTORCH_ALLOC_CONF
      value: "per_process_memory_fraction:0.8"
    - name: VLLM_PLE_TABLE_MEMORY
      value: "device"
    - name: CUTE_DSL_ARCH
      value: "sm_121a"
    - name: SAFETENSORS_FAST_GPU
      value: "1"
    - name: VLLM_WORKER_MULTIPROC_METHOD
      value: "spawn"
    - name: VLLM_SSM_CONV_STATE_LAYOUT
      value: "DS"
    - name: VLLM_USE_AOT_COMPILE
      value: "1"
    - name: VLLM_USE_MEGA_AOT_ARTIFACT
      value: "1"
    - name: VLLM_USE_V2_MODEL_RUNNER
      value: "1"
    - name: B12X_POLICY_MODE
      value: "auto"
    - name: VLLM_MXFP8_LM_HEAD
      value: "1"
    - name: VLLM_B12X_MOE_FP4_LAYER_MAX_INPUT_SCALE
      value: "w13"
    - name: VLLM_B12X_MOE_FP4_FORCE_A16
      value: "1"
    - name: B12X_W4A16_A4_PREFILL
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 13. qwen3.8-coder-next-fp8.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Intel/Qwen3-Coder-Next-FP8
# Recipe: qwen3-coder-next-fp8.yaml
# Single-node TP=1, FP8 format
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen38-coder-next-fp8
spec:
  source: hf://Intel/Qwen3-Coder-Next-FP8
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving for Qwen3-Coder-Next-FP8
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen38-coder-next-fp8
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen38-coder-next-fp8
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 14. qwen3.8-coder-next-int4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: Intel/Qwen3-Coder-Next-int4-AutoRound
# Recipe: qwen3-coder-next-int4-autoround.yaml
# Single-node TP=1, INT4 AWQ quantization
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: qwen38-coder-next-int4
spec:
  source: hf://Intel/Qwen3-Coder-Next-int4-AutoRound
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving for Qwen3-Coder-Next-int4
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: qwen38-coder-next-int4
  labels:
    krr/ignore: "true"
spec:
  modelRef: qwen38-coder-next-int4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

---

## Gemma / DiffusionGemma Family (6 recipes)

### 15. gemma4-26b.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: google/gemma-4-26B-A4B-it
# Recipe: gemma4-26b-a4b.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: gemma4-26b
spec:
  source: hf://google/gemma-4-26B-A4B-it
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: gemma4-26b
  labels:
    krr/ignore: "true"
spec:
  modelRef: gemma4-26b
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format safetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 16. gemma4-26b-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/diffusiongemma-26B-A4B-it-NVFP4
# Recipe: diffusion-gemma-nvfp4.yaml
# Single-node TP=1, NVFP4 quantization
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: gemma4-26b-nvfp4
spec:
  source: hf://nvidia/diffusiongemma-26B-A4B-it-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: gemma4-26b-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: gemma4-26b-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --reasoning-parser gemma4
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 17. diffusiongemma-bf16.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: google/diffusiongemma-26B-A4B-it
# Recipe: diffusion-gemma-bf16.yaml
# Single-node TP=1, BF16 format, thinking disabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: diffusiongemma-bf16
spec:
  source: hf://google/diffusiongemma-26B-A4B-it
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: bf16
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, BF16, thinking disabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: diffusiongemma-bf16
  labels:
    krr/ignore: "true"
spec:
  modelRef: diffusiongemma-bf16
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --reasoning-parser gemma4
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 18. diffusiongemma-bf16-thinking.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: google/diffusiongemma-26B-A4B-it (thinking enabled)
# Recipe: diffusion-gemma-bf16-thinking.yaml
# Single-node TP=1, BF16 format, thinking enabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: diffusiongemma-bf16-thinking
spec:
  source: hf://google/diffusiongemma-26B-A4B-it
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: bf16
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, BF16, thinking enabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: diffusiongemma-bf16-thinking
  labels:
    krr/ignore: "true"
spec:
  modelRef: diffusiongemma-bf16-thinking
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --reasoning-parser gemma4
  env:
    - name: VLLM_USE_THINKING
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 19. diffusiongemma-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/diffusiongemma-26B-A4B-it-NVFP4 (thinking disabled)
# Recipe: diffusion-gemma-nvfp4.yaml
# Single-node TP=1, NVFP4 quantization, thinking disabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: diffusiongemma-nvfp4
spec:
  source: hf://nvidia/diffusiongemma-26B-A4B-it-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, NVFP4, thinking disabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: diffusiongemma-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: diffusiongemma-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --reasoning-parser gemma4
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 20. diffusiongemma-nvfp4-thinking.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/diffusiongemma-26B-A4B-it-NVFP4 (thinking enabled)
# Recipe: diffusion-gemma-nvfp4-thinking.yaml
# Single-node TP=1, NVFP4 quantization, thinking enabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: diffusiongemma-nvfp4-thinking
spec:
  source: hf://nvidia/diffusiongemma-26B-A4B-it-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, NVFP4, thinking enabled
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: diffusiongemma-nvfp4-thinking
  labels:
    krr/ignore: "true"
spec:
  modelRef: diffusiongemma-nvfp4-thinking
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --reasoning-parser gemma4
  env:
    - name: VLLM_USE_THINKING
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

---

## Nemotron Family (5 recipes)

### 21. nemotron-3-nano-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4
# Recipe: nemotron-3-nano-nvfp4.yaml
# Single-node TP=1, NVFP4 quantization, Marlin backend
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: nemotron-3-nano-nvfp4
spec:
  source: hf://nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + Marlin backend
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: nemotron-3-nano-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: nemotron-3-nano-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --max-num-seqs 8
    - --gpu-memory-utilization 0.7
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-auto-tool-choice
    - --tool-call-parser qwen3_coder
    - --reasoning-parser nano_v3
    - --reasoning-parser-plugin nano_v3_reasoning_parser.py
  env:
    - name: VLLM_USE_FLASHINFER_MOE_FP4
      value: "1"
    - name: VLLM_FLASHINFER_MOE_BACKEND
      value: "throughput"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 22. nemotron-3-super-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4
# Recipe: nemotron-3-super-nvfp4.yaml
# Single-node TP=1 or cluster TP=2, NVFP4 quantization, Marlin backend
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: nemotron-3-super-nvfp4
spec:
  source: hf://nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + Marlin backend
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: nemotron-3-super-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: nemotron-3-super-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 23. nemotron-3.5-super-vl-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4
# Recipe: nemotron-3.5-super-vl-nvfp4.yaml
# Single-node TP=1, NVFP4 quantization, DFlash speculative decoding
# Vision + video input support
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: nemotron-3.5-super-vl-nvfp4
spec:
  source: hf://nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + DFlash
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: nemotron-3.5-super-vl-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: nemotron-3.5-super-vl-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --max-num-seqs 8
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format instanttensor
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --speculative-config '{"method":"dflash","model":"nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4-DSpark","num_speculative_tokens":7,"draft_tensor_parallel_size":1}'
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 24. nemotron-3.5-bolt-24gb.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB
# Recipe: nemotron-3.5-bolt-24gb.yaml
# Single-node TP=1, NVFP4 quantization, DFlash speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: nemotron-3.5-bolt-24gb
spec:
  source: hf://nvidia/NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + DFlash
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: nemotron-3.5-bolt-24gb
  labels:
    krr/ignore: "true"
spec:
  modelRef: nemotron-3.5-bolt-24gb
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 8192
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 8192
    - --max-num-batched-tokens 4096
    - --max-num-seqs 8
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format instanttensor
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --speculative-config '{"method":"dflash","model":"nvidia/NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB-DSpark","num_speculative_tokens":7,"draft_tensor_parallel_size":1}'
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 25. nemotron-3.5-lightning-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4
# Recipe: nemotron-3.5-lightning.yaml
# Single-node TP=1, NVFP4 quantization, DSpark speculative decoding
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: nemotron-3.5-lightning-nvfp4
spec:
  source: hf://nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with NVFP4 + DSpark
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: nemotron-3.5-lightning-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: nemotron-3.5-lightning-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --speculative-config '{"method":"dspark","num_speculative_tokens":6,"draft_sample_method":"probabilistic"}'
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

---

## DeepSeek Family (3 recipes)

### 26. deepseek-v4-flash.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: deepseek-ai/DeepSeek-V4-Flash
# Recipe: deepseek-v4-flash.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: deepseek-v4-flash
spec:
  source: hf://deepseek-ai/DeepSeek-V4-Flash
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: deepseek-v4-flash
  labels:
    krr/ignore: "true"
spec:
  modelRef: deepseek-v4-flash
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --tokenizer-mode deepseek_v4
    - --tool-call-parser deepseek_v4
    - --enable-auto-tool-choice
    - --reasoning-parser deepseek_v4
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 27. deepseek-v4-flash-0731.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: deepseek-ai/DeepSeek-V4-Flash-0731
# Recipe: deepseek-v4-flash-0731.yaml
# B12X-optimized cluster serving, TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: deepseek-v4-flash-0731
spec:
  source: hf://deepseek-ai/DeepSeek-V4-Flash-0731
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, B12X image, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: deepseek-v4-flash-0731
  labels:
    krr/ignore: "true"
spec:
  modelRef: deepseek-v4-flash-0731
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm-b12x:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --tokenizer-mode deepseek_v4
    - --tool-call-parser deepseek_v4
    - --enable-auto-tool-choice
    - --reasoning-parser deepseek_v4
  env:
    - name: CUTE_DSL_ARCH
      value: "sm_121a"
    - name: VLLM_USE_AOT_COMPILE
      value: "1"
    - name: VLLM_USE_BREAKABLE_CUDAGRAPH
      value: "0"
    - name: VLLM_USE_MEGA_AOT_ARTIFACT
      value: "1"
    - name: VLLM_MEMORY_PROFILE_INCLUDE_ATTN
      value: "1"
    - name: VLLM_USE_FLASHINFER_SAMPLER
      value: "1"
    - name: VLLM_USE_B12X_WO_PROJECTION
      value: "1"
    - name: VLLM_USE_B12X_MHC
      value: "1"
    - name: VLLM_USE_B12X_FP8_GEMM
      value: "1"
    - name: VLLM_USE_B12X_MOE
      value: "1"
    - name: VLLM_USE_B12X_SPARSE_INDEXER
      value: "1"
    - name: VLLM_USE_V2_MODEL_RUNNER
      value: "1"
    - name: VLLM_MOE_SKIP_PADDING
      value: "0"
    - name: B12X_MLA_SM120_UNIFIED
      value: "1"
    - name: B12X_MOE_FORCE_A8
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 28. deepseek-v4-flash-vision-exp.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: deepseek-ai/DeepSeek-V4-Flash-Vision-Exp
# Recipe: deepseek-v4-flash-vision-exp.yaml
# B12X-optimized cluster serving, TP=2 across 2 DGX Spark nodes
# Vision-enabled MoE model, DSpark speculative decoding
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: deepseek-v4-flash-vision-exp
spec:
  source: hf://deepseek-ai/DeepSeek-V4-Flash-Vision-Exp
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: bfloat16
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, B12X image, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: deepseek-v4-flash-vision-exp
  labels:
    krr/ignore: "true"
spec:
  modelRef: deepseek-v4-flash-vision-exp
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm-b12x:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 8192
  maxCudagraphCaptureSize: 48
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --trust-remote-code
    - --max-model-len 262144
    - --max-num-seqs 8
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --block-size 256
    - --enable-prefix-caching
    - --tokenizer-mode deepseek_v4
    - --tool-call-parser deepseek_v4
    - --enable-auto-tool-choice
    - --reasoning-parser deepseek_v4
    - --load-format instanttensor
    - --moe-backend b12x
    - --linear-backend b12x
    - --attention-backend B12X
    - --max-cudagraph-capture-size 48
    - --compilation-config '{"cudagraph_mode":"FULL_AND_PIECEWISE","custom_ops":["all"]}'
    - --speculative-config '{"method":"dspark","num_speculative_tokens":6,"draft_sample_method":"probabilistic","attention_backend":"B12X"}'
    - --tensor-parallel-size 2
  env:
    - name: CUTE_DSL_ARCH
      value: "sm_121a"
    - name: VLLM_USE_AOT_COMPILE
      value: "1"
    - name: VLLM_USE_BREAKABLE_CUDAGRAPH
      value: "0"
    - name: VLLM_USE_MEGA_AOT_ARTIFACT
      value: "1"
    - name: VLLM_MEMORY_PROFILE_INCLUDE_ATTN
      value: "1"
    - name: VLLM_USE_FLASHINFER_SAMPLER
      value: "1"
    - name: VLLM_USE_B12X_WO_PROJECTION
      value: "1"
    - name: VLLM_USE_B12X_MHC
      value: "1"
    - name: VLLM_USE_B12X_FP8_GEMM
      value: "1"
    - name: VLLM_USE_B12X_MOE
      value: "1"
    - name: VLLM_USE_B12X_SPARSE_INDEXER
      value: "1"
    - name: VLLM_USE_V2_MODEL_RUNNER
      value: "1"
    - name: VLLM_MOE_SKIP_PADDING
      value: "0"
    - name: B12X_MLA_SM120_UNIFIED
      value: "1"
    - name: B12X_MOE_FORCE_A8
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## GLM Family (2 recipes)

### 29. glm-4.7-flash-awq.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: cyankiwi/GLM-4.7-Flash-AWQ-4bit
# Recipe: glm-4.7-flash-awq.yaml
# Single-node TP=1, AWQ quantization
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: glm-4.7-flash-awq
spec:
  source: hf://cyankiwi/GLM-4.7-Flash-AWQ-4bit
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 1
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving with AWQ
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: glm-4.7-flash-awq
  labels:
    krr/ignore: "true"
spec:
  modelRef: glm-4.7-flash-awq
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 1
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 202752
  maxNumBatchedTokens: 4096
  parallelSlots: 1
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "32Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 202752
    - --max-num-batched-tokens 4096
    - --max-num-seqs 64
    - --gpu-memory-utilization 0.7
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --enable-prefix-caching
    - --enable-auto-tool-choice
    - --tool-call-parser glm47
    - --reasoning-parser glm45
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
```

### 30. glm-5.3-flash-fp4-local.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: nvidia/GLM-5.3-Flash-NVFP4-Spark
# Recipe: glm-5.3-flash.yaml
# B12X-optimized cluster serving, TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: glm-5.3-flash-fp4-local
spec:
  source: hf://nvidia/GLM-5.3-Flash-NVFP4-Spark
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, B12X image, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: glm-5.3-flash-fp4-local
  labels:
    krr/ignore: "true"
spec:
  modelRef: glm-5.3-flash-fp4-local
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm-b12x:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 262144
  maxNumBatchedTokens: 4096
  batchSize: 4096
  uBatchSize: 4096
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 262144
    - --max-num-batched-tokens 4096
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format b12x
    - --moe-backend b12x
    - --linear-backend b12x
    - --attention-backend B12X
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
    - --speculative-config '{"method":"mtp","num_speculative_tokens":4}'
  env:
    - name: CUTE_DSL_ARCH
      value: "sm_121a"
    - name: VLLM_USE_AOT_COMPILE
      value: "1"
    - name: VLLM_USE_BREAKABLE_CUDAGRAPH
      value: "0"
    - name: VLLM_USE_MEGA_AOT_ARTIFACT
      value: "1"
    - name: VLLM_USE_FLASHINFER_SAMPLER
      value: "1"
    - name: VLLM_USE_B12X_WO_PROJECTION
      value: "1"
    - name: VLLM_USE_B12X_MHC
      value: "1"
    - name: VLLM_USE_B12X_FP8_GEMM
      value: "1"
    - name: VLLM_USE_B12X_MOE
      value: "1"
    - name: VLLM_USE_B12X_SPARSE_INDEXER
      value: "1"
    - name: VLLM_USE_V2_MODEL_RUNNER
      value: "1"
    - name: VLLM_MOE_SKIP_PADDING
      value: "0"
    - name: B12X_MLA_SM120_UNIFIED
      value: "1"
    - name: B12X_MOE_FORCE_A8
      value: "1"
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## MiniMax Family (3 recipes)

### 31. minimax-m2-awq.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: QuantTrio/MiniMax-M2-AWQ-4bit
# Recipe: minimax-m2-awq.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: minimax-m2-awq
spec:
  source: hf://QuantTrio/MiniMax-M2-AWQ-4bit
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: minimax-m2-awq
  labels:
    krr/ignore: "true"
spec:
  modelRef: minimax-m2-awq
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 32. minimax-m2.5-awq.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: MiniMax-Text-01-AWQ (M2.5)
# Recipe: minimax-m2.5-awq.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: minimax-m2.5-awq
spec:
  source: hf://MiniMax-Text-01-AWQ
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: minimax-m2.5-awq
  labels:
    krr/ignore: "true"
spec:
  modelRef: minimax-m2.5-awq
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 33. minimax-m2.7-awq.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: cyankiwi/MiniMax-M2.7-AWQ-4bit
# Recipe: minimax-m2.7-awq.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: minimax-m2.7-awq
spec:
  source: hf://cyankiwi/MiniMax-M2.7-AWQ-4bit
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: awq
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: minimax-m2.7-awq
  labels:
    krr/ignore: "true"
spec:
  modelRef: minimax-m2.7-awq
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## Step Family (2 recipes)

### 34. step-3.7-flash-fp8.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: stepfun-ai/Step-3.7-Flash-FP8
# Recipe: step-3.7-flash-fp8.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: step-3.7-flash-fp8
spec:
  source: hf://stepfun-ai/Step-3.7-Flash-FP8
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: fp8
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: step-3.7-flash-fp8
  labels:
    krr/ignore: "true"
spec:
  modelRef: step-3.7-flash-fp8
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 35. step-3.7-flash-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: stepfun-ai/Step-3.7-Flash-NVFP4
# Recipe: step-3.7-flash-nvfp4.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: step-3.7-flash-nvfp4
spec:
  source: hf://stepfun-ai/Step-3.7-Flash-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: step-3.7-flash-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: step-3.7-flash-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## Others (2 recipes)

### 36. inkling-small-nvfp4.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: thinkingmachines/Inkling-Small-NVFP4
# Recipe: inkling-small-nvfp4.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: inkling-small-nvfp4
spec:
  source: hf://thinkingmachines/Inkling-Small-NVFP4
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: nvfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: inkling-small-nvfp4
  labels:
    krr/ignore: "true"
spec:
  modelRef: inkling-small-nvfp4
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.8
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-chunked-prefill
    - --async-scheduling
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

### 37. openai-gpt-oss-120b.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/model_v1alpha1.json
# Model: openai/gpt-oss-120b
# Recipe: gpt-oss-120b.yaml
# Cluster-only: TP=2 across 2 DGX Spark nodes
# NOTE: Requires multiNode configuration with RDMA fabric
# NOTE: Uses MXFP4 quantization (--exp-mxfp4 build profile)
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: openai-gpt-oss-120b
spec:
  source: hf://openai/gpt-oss-120b
  sourceSecretRef:
    name: huggingface
  format: safetensors
  quantization: mxfp4
  hardware:
    accelerator: cuda
    gpu:
      enabled: true
      vendor: nvidia
      count: 2
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/inference.llmkube.dev/inferenceservice_v1alpha1.json
# InferenceService: vLLM serving, multi-node TP=2
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: openai-gpt-oss-120b
  labels:
    krr/ignore: "true"
spec:
  modelRef: openai-gpt-oss-120b
  modelCache:
    claimName: llmkube-ganyu-cache
  runtime: vllm
  image: eugr/spark-vllm:latest
  rolloutPolicy:
    waitForIdle: true
    idleTimeoutSeconds: 86400
  replicas: 2
  priority: high
  nodeSelector:
    nvidia.com/gpu.present: "true"
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  contextSize: 131072
  maxNumBatchedTokens: 8192
  batchSize: 8192
  uBatchSize: 8192
  resources:
    cpu: "1000m"
    memory: "64Gi"
    nvidia.com/gpu: "1"
  endpoint:
    port: 8000
    type: ClusterIP
  extraArgs:
    - --host 0.0.0.0
    - --port 8000
    - --max-model-len 131072
    - --max-num-batched-tokens 8192
    - --gpu-memory-utilization 0.7
    - --kv-cache-dtype fp8
    - --load-format fastsafetensors
    - --attention-backend flashinfer
    - --tensor-parallel-size 2
    - --enable-prefix-caching
    - --enable-auto-tool-choice
    - --tool-call-parser openai
    - --reasoning-parser openai_gptoss
  probeOverrides:
    startup:
      httpGet:
        path: /health
        port: 8000
      periodSeconds: 10
      failureThreshold: 360
    liveness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 30
      periodSeconds: 30
      failureThreshold: 6
    readiness:
      httpGet:
        path: /health
        port: 8000
      initialDelaySeconds: 20
      periodSeconds: 10
      failureThreshold: 6
  multiNode:
    rdmaResource: rdma/rdma_shared_device_a
    ibGIDIndex: 3
    members:
      - node: spark1
        fabric:
          address: 10.200.15.71
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark1-model-cache
      - node: spark2
        fabric:
          address: 10.200.15.72
          socketInterface: enP7s7
          ibHCA: "rocep1s0f0,rocep1s0f1,roceP2p1s0f0,roceP2p1s0f1"
        modelCache:
          claimName: spark2-model-cache
```

---

## Summary

| Family | Count | Image | B12X |
|--------|-------|-------|------|
| Qwen3.6 | 5 | `eugr/spark-vllm:latest` | No |
| Qwen3.5 | 4 | `eugr/spark-vllm:latest` | No |
| Qwen3.8 | 5 | `eugr/spark-vllm:latest` / `eugr/spark-vllm-b12x:latest` | 2 |
| Gemma/DiffusionGemma | 6 | `eugr/spark-vllm:latest` | No |
| Nemotron | 5 | `eugr/spark-vllm:latest` | No |
| DeepSeek | 3 | `eugr/spark-vllm:latest` / `eugr/spark-vllm-b12x:latest` | 2 |
| GLM | 2 | `eugr/spark-vllm:latest` / `eugr/spark-vllm-b12x:latest` | 1 |
| MiniMax | 3 | `eugr/spark-vllm:latest` | No |
| Step | 2 | `eugr/spark-vllm:latest` | No |
| Others | 2 | `eugr/spark-vllm:latest` | No |
| **Total** | **37** | | **5 B12X** |

**All fixes applied:**
- `count` instead of `tensorParallelism` in all Model specs
- `$schema` annotations on both Model and InferenceService
- `probeOverrides` on all InferenceServices
- `eugr/spark-vllm-b12x:latest` for B12X recipes (5 total)
- `eugr/spark-vllm:latest` for all other recipes
- No `--distributed-executor-backend ray` in extraArgs
- All original parameters preserved
