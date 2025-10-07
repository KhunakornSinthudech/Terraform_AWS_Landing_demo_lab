#read event from S3 trigger and submit MediaConvert job
#output as 720p mp4 h264/aac to output bucket

import os, json, urllib.parse, boto3

INPUT_BUCKET  = os.environ["INPUT_BUCKET"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
INPUT_PREFIX  = os.environ.get("INPUT_PREFIX", "input/")
OUTPUT_PREFIX = os.environ.get("OUTPUT_PREFIX", "outputs/")
QUEUE_ARN     = os.environ["QUEUE_ARN"]
SERVICE_ROLE  = os.environ["SERVICE_ROLE"]
REGION        = os.environ("AWS_REGION", None)

def _mc_client():
  # get mc endpoint url
  mc = boto3.client("mediaconvert", region_name=REGION)
  ep = mc.describe_endpoints(MaxResults=1)["Endpoints"][0]["Url"]
  # create new client with this endpoint
  return boto3.client("mediaconvert", region_name=REGION, endpoint_url=ep)

def main(event, context):
  # Extract bucket/key from S3 event
  rec = event["Records"][0] # get first record
  bkt = rec["s3"]["bucket"]["name"] # read bucket name
  key = urllib.parse.unquote_plus(rec["s3"]["object"]["key"]) # read object key and URl : use unquote_plus to decode URL-encoded chars

  # only process my input prefix and bucket name
  if bkt != INPUT_BUCKET or not key.startswith(INPUT_PREFIX):
    return {"skip": True, "bucket": bkt, "key": key}

  src  = f"s3://{bkt}/{key}"
  dest = f"s3://{OUTPUT_BUCKET}/{OUTPUT_PREFIX}"

    # submit job
  mc = _mc_client()
  job = mc.create_job(
    Queue=QUEUE_ARN,
    Role=SERVICE_ROLE,
    Settings={
      "Inputs": [{ "FileInput": src }],
      "OutputGroups": [{
        "Name": "File Group",
        "OutputGroupSettings": {
          "Type": "FILE_GROUP_SETTINGS",
          "FileGroupSettings": { "Destination": dest }
        },
        "Outputs": [{
          "ContainerSettings": { "Container": "MP4" }, # MP4 is widely supported without custom codec installation
          "VideoDescription": {
            "Width": 1280,
            "Height": 720,
            "ScalingBehavior": "DEFAULT",  # fit to width/height
            "Sharpness": 50,  # default is 50
            "AntiAlias": "ENABLED", # enable anti-aliasing          
            "CodecSettings": {
              "Codec": "H_264", # H.264 is widely supported even potato devices
              "H264Settings": {
                "RateControlMode": "QVBR", # I think this is better than CBR or VBR for most use cases
                "SceneChangeDetect": "TRANSITION_DETECTION" # improve quality on scene changes : no max bitrate for demo
              }
            }
          },
          "AudioDescriptions": [{
            "CodecSettings": {
              "Codec": "AAC", # AAC is widely supported no license issue
              "AacSettings": {
                "Bitrate": 96000, # 96kbps is good enough for most use cases
                "CodingMode": "CODING_MODE_2_0", # stereo is ok for demo, not sure for Mediagenix customers
                "SampleRate": 48000 # 48kHz is standard for video good enough for my demo
              }
            }
          }]
        }]
      }]
    },
    StatusUpdateInterval="SECONDS_60"
  )
  return {"jobId": job["Job"]["Id"], "src": src, "dest": dest}
