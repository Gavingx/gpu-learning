## Faster-Bert-As-Service
高性能BERT推理服务

`GPU_MODEL=850M PRETRAIN_DIR=`pwd`/pretrain-models/bert-base-chinese 
python3 builder.py -m $PRETRAIN_DIR/bert_model.ckpt 
 -o /root/kan/models/bert-base-chinese/1/model.plan -s 64 -g -b 1 -b 2 -w 1800 -c $PRETRAIN_DIR`

`LD_PRELOAD=/root/kan/libnvinfer_plugin_gtx850m.so tritonserver --model-store=/root/kan/models --strict-model-config=false --http-thread-count 32`