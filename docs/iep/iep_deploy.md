


(devbox) ubuntu@nai-llm-jumphost:~/nai-llm-fleet-infra$ k get po
NAME                                             READY   STATUS    RESTARTS   AGE
nai-c0d6ca61-1629-43d2-b57a-9f-model-job-9nmff   1/1     Running   0          4m49s
(devbox) ubuntu@nai-llm-jumphost:~/nai-llm-fleet-infra$ k get jobs
NAME                                       COMPLETIONS   DURATION   AGE
nai-c0d6ca61-1629-43d2-b57a-9f-model-job   0/1           4m56s      4m56


k logs -f nai-c0d6ca61-1629-43d2-b57a-9f-model-job-9nmff 

/venv/lib/python3.9/site-packages/huggingface_hub/file_download.py:983: UserWarning: Not enough free disk space to download the file. The expected file size is: 0.05 MB. The target location /data/model-files only has 0.00 MB free disk space.
  warnings.warn(
tokenizer_config.json: 100%|██████████| 51.0k/51.0k [00:00<00:00, 3.26MB/s]
tokenizer.json: 100%|██████████| 9.09M/9.09M [00:00<00:00, 35.0MB/s]<00:30, 150MB/s]
model-00004-of-00004.safetensors: 100%|██████████| 1.17G/1.17G [00:12<00:00, 94.1MB/s]
model-00001-of-00004.safetensors: 100%|██████████| 4.98G/4.98G [04:23<00:00, 18.9MB/s]
model-00003-of-00004.safetensors: 100%|██████████| 4.92G/4.92G [04:33<00:00, 18.0MB/s]
model-00002-of-00004.safetensors: 100%|██████████| 5.00G/5.00G [04:47<00:00, 17.4MB/s]
Fetching 16 files: 100%|██████████| 16/16 [05:42<00:00, 21.43s/it]:33<00:52, 9.33MB/s]
## Successfully downloaded model_files|██████████| 5.00G/5.00G [04:47<00:00, 110MB/s] 

Deleting directory : /data/hf_cache