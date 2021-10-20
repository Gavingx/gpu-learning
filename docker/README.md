# Unified GPU Environment 
训练推理一体化GPU环境搭建

## 固定CPU频率
启用CPU睿频时GPU训练效率会下降
- 禁用休眠  
  `cpupower idle-set -D 0`
- 启动性能模式   
  `cpupower -c all frequency-set -g performance`

## NFS挂载
用于多台GPU机器之间的文件共享(服务器重启后需要重新挂载)  
 `mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 
 xx.xx.xx.xx:/data /data/nfs`

## 构建镜像
`export NGC_VERSION=21.09 && `     
`docker build --build-arg NGC_VERSION=${NGC_VERSION} -t rivia/pytorch:${NGC_VERSION} -f pytorch.Dockerfile . && `  
`docker build --build-arg NGC_VERSION=${NGC_VERSION} -t rivia/tensorflow-1:${NGC_VERSION} -f tensorflow.Dockerfile . && `  
`docker build --build-arg NGC_VERSION=${NGC_VERSION} -t rivia/triton:${NGC_VERSION} -f triton.Dockerfile . && `  
`docker build -t rivia/tensorrt:8.0.3 -f tensorrt.Dockerfile .`  

> TensorRT的版本要与Triton Server版本保持兼容, 版本对应关系参考[支持矩阵](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html)

## 启动容器
替换为自己要设置的密码和用户  
`sed -i "s/aigroup/your_username/g" gpu.yml`   
`sed -i "s/123456/your_password/g" gpu.yml`  

启动容器  
`docker-compose -p gpu -f gpu.yml up -d`

> 包括:
> 
> - Tensorflow容器用于模型的训练
> - Triton Server容器用于模型的推理
> - TensorRT容器用于构建推理图
> - Tensorboard容器


## TODO
- [ ] 支持 [TVM](https://github.com/apache/tvm) 
- [ ] 支持 [DeepSpeed](https://github.com/microsoft/DeepSpeed)
- [ ] 支持 [Megatron](https://github.com/NVIDIA/Megatron-LM)



