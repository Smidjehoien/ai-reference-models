ARGS="--dtype int8 --int8-prepare --ipex-merged-emb-cat --int8-configure-dir ${INT8_CONFIG}"
python $MODEL_SCRIPT \
    --embedding_dim 128 \
    --dense_arch_layer_sizes 512,256,128 \
    --over_arch_layer_sizes 1024,1024,512,256,1 \
    --num_embeddings_per_feature 40000000,39060,17295,7424,20265,3,7122,1543,63,40000000,3067956,405282,10,2209,11938,155,4,976,14,40000000,40000000,40000000,590152,12973,108,36 \
    --epochs 1 \
    --pin_memory \
    --mmap_mode \
    --batch_size $BATCH_SIZE \
    --interaction_type=dcn \
    --dcn_num_layers=3 \
    --dcn_low_rank_dim=512 \
    --limit_val_batches 1000 \
    --ipex-optimize \
    --log-freq 10 \
    --jit \
    --inference-only \
    --benchmark \
    $ARGS $EXTRA_ARGS
