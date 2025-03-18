#! /bin/bash

set -e

SRC=$1
DEST=$2

echo "#######################################"
echo "Running default storage initializer..."
./download-model $@
echo "Default storage initializer completed!"
echo "#######################################"
echo ""

# variables provided via ClusterStorageContainer
MODEL_ENCRYPTED=${MODEL_ENCRYPTED:-false} # whether to decrypt the model or not
MODEL_DECRYPTION_KEY=${MODEL_DECRYPTION_KEY:-"model-keys/model-name.key"} # path to the secret/file in Trustee
MODEL_NAME=${MODEL_NAME:-"model"} # name of the model, without format
MODEL_FORMAT=${MODEL_FORMAT:-"onnx"} # format of the model

if ! $MODEL_ENCRYPTED 2> /dev/null; then
    exit 0
fi

echo "MODEL_ENCRYPTED: $MODEL_ENCRYPTED"
echo "MODEL_DECRYPTION_KEY: $MODEL_DECRYPTION_KEY"
echo "MODEL_NAME: $MODEL_NAME"
echo "MODEL_FORMAT: $MODEL_FORMAT"
echo ""

KEY_FOLDER=/tmp/keys # save key in memory-backed fs
mkdir $KEY_FOLDER
KEY_FILE=$KEY_FOLDER/key.bin

MODEL_PATH_DIR=$DEST
MODEL_PATH="$MODEL_PATH_DIR/$MODEL_NAME.$MODEL_FORMAT"
ALT_MODEL_PATH_DIR="$DEST/1"
ALT_MODEL_PATH="$ALT_MODEL_PATH_DIR/$MODEL_NAME.$MODEL_FORMAT"

MODEL_FILE_DIR=""
MODEL_FILE=""
if [ -f "$MODEL_PATH.enc" ]; then
    MODEL_FILE=$MODEL_PATH
    MODEL_FILE_DIR=$MODEL_PATH_DIR
elif [ -f "$ALT_MODEL_PATH.enc" ]; then
    MODEL_FILE=$ALT_MODEL_PATH
    MODEL_FILE_DIR=$ALT_MODEL_PATH_DIR
else
    echo "Model $MODEL_NAME.$MODEL_FORMAT not found in $MODEL_PATH_DIR nor $ALT_MODEL_PATH_DIR. Where is it?"
    ls -R $DEST
    exit 1
fi
echo "Model found in $MODEL_FILE!"
MODEL_FILE_ENC=$MODEL_FILE.enc
echo ""

echo "MODEL_FILE_ENC $MODEL_FILE_ENC"
echo ""

# export S3_VERIFY_SSL=0

echo "Models downloaded:"
ls -R $DEST
echo ""

echo "Content of $KEY_FOLDER:"
ls -R $KEY_FOLDER
echo ""

echo "Downloading the key:"
curl -L http://127.0.0.1:8006/cdh/resource/default/$MODEL_DECRYPTION_KEY -o $KEY_FILE
echo ""

echo "Content of $KEY_FOLDER:"
ls -R $KEY_FOLDER
echo ""

echo "Decrypting model:"
openssl enc -d -aes-256-cbc -pbkdf2 -kfile $KEY_FILE -in $MODEL_FILE_ENC -out $MODEL_FILE
echo "Decription completed!"
echo ""

if [ "$MODEL_FORMAT" == "tar.gz" ]; then
    echo "Extracting $MODEL_FILE to $MODEL_FILE_DIR..."
    tar -xzvf "$MODEL_FILE" -C "$MODEL_FILE_DIR" --strip-components=1
    echo "Extraction completed."
    echo ""

    rm -rf $MODEL_FILE
fi

echo "Final model directory layout:"
ls -R $DEST
echo ""

rm -rf $MODEL_FILE_ENC