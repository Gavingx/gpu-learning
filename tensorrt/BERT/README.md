## Faster-Bert-As-Service
高性能BERT推理服务

`GPU_MODEL=850M PRETRAIN_DIR=`pwd`/pretrain-models/bert-base-chinese 
python3 builder.py -m $PRETRAIN_DIR/bert_model.ckpt 
 -o /root/kan/models/bert-base-chinese/1 -s 64 -g -b 1 -b 2 -b 4 -c $PRETRAIN_DIR`