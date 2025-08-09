#!/bin/bash

api="${GOOGLE_API_KEY}"

spectacle -r -b -o /tmp/screenshot.png &
pid=$!
gemini_version="gemini-2.5-flash"

text=$(zenity --text-info --ok-label="Ask" --title="Ask a question" --editable --text="Enter your question text:")
if [ "$?" != 0 ]
then
    exit
fi

echo "Waiting for spectacle (PID: $pid)..."

wait $pid


get_response() {

    local image_path="$1"
    convert "$image_path" -resize 50% /tmp/screenshot_half.png

    local description="$2"

    IMAGE_PATH="/tmp/screenshot_half.png"
    MIME_TYPE=$(file -b --mime-type "${IMAGE_PATH}")
    NUM_BYTES=$(wc -c < "${IMAGE_PATH}")
    DISPLAY_NAME="IMAGE"

    tmp_header_file=upload-header.tmp

    curl "https://generativelanguage.googleapis.com/upload/v1beta/files?key=$api" \
      -D upload-header.tmp \
      -H "X-Goog-Upload-Protocol: resumable" \
      -H "X-Goog-Upload-Command: start" \
      -H "X-Goog-Upload-Header-Content-Length: ${NUM_BYTES}" \
      -H "X-Goog-Upload-Header-Content-Type: ${MIME_TYPE}" \
      -H "Content-Type: application/json" \
      -d "{
        \"file\": {
          \"display_name\": \"${DISPLAY_NAME}\"
        }
      }" 2> /dev/null

    upload_url=$(grep -i "x-goog-upload-url: " "${tmp_header_file}" | cut -d" " -f2 | tr -d "\r")
    rm "${tmp_header_file}"

    curl "${upload_url}" \
      -H "Content-Length: ${NUM_BYTES}" \
      -H "X-Goog-Upload-Offset: 0" \
      -H "X-Goog-Upload-Command: upload, finalize" \
      --data-binary "@${IMAGE_PATH}" 2> /dev/null > /tmp/file_info.json

    file_uri=$(jq -r ".file.uri" /tmp/file_info.json)

    curl "https://generativelanguage.googleapis.com/v1beta/models/$gemini_version:generateContent?key=$api" \
        -H 'Content-Type: application/json' \
        -X POST \
        -d "{
          \"contents\": [{
            \"parts\": [
              {
                \"file_data\": {
                  \"mime_type\": \"${MIME_TYPE}\",
                  \"file_uri\": \"${file_uri}\"
                }
              },
              {
                \"text\": \"$description\"
              }
            ]
          }]
        }" 2> /dev/null > /tmp/response.json

    output_text="$(jq -r ".candidates[].content.parts[].text" /tmp/response.json)"

    echo "$output_text"
}

get_response_no_pic() {
    local description="$1"
    tmp_header_file=upload-header.tmp

curl "https://generativelanguage.googleapis.com/v1beta/models/$gemini_version:generateContent?key=$api" \
    -H 'Content-Type: application/json' \
    -X POST \
    -d "$(jq -n --arg description "$description" '{
        contents: [
            {
                parts: [
                    {
                        text: $description
                    }
                ]
            }
        ]
    }')" 2> /dev/null > /tmp/response.json


    output_text="$(jq -r ".candidates[].content.parts[].text" /tmp/response.json)"

    echo "$output_text"
}

if [[ -e "/tmp/screenshot.png" ]]
then
    response="$(get_response "/tmp/screenshot.png" "Analyze what you see in this picture and answer the next question about it in a brief but precise way: $text")"

    name_gemini=$(jq ".file.name" /tmp/file_info.json | cut -d'/' -f2- | cut -d'"' -f1-1)
    curl --request "DELETE" https://generativelanguage.googleapis.com/v1beta/files/$name_gemini?key=$api

    zenity --text-info --ok-label="Ask again" --title="Answer to the question" --width=500 --height=400 --filename=<(echo  "$response")
    rm "/tmp/screenshot.png"
    rm "/tmp/screenshot_half.png"

else
    response="$(get_response_no_pic "Answer the question in a brief but precise way, and if the answer needed is only a bash command for linux, provide only the command to run without any format after the keyword BASH: command. If the question is not about a command, answer normally. 
    The question is: $text")"

    if [[ "$response" == *"BASH:"* ]]; then
    echo "$response"
    command=${response//BASH:/}
    command="${command//\`\`\`bash/}"
    command="${command//\`/}"
    echo "$command"
    konsole --noclose -e bash -i -c "read -p 'Do you want to run the command? (Enter to confirm): $command' confirm; bash -c '$command' &"

    else
        zenity --text-info --ok-label="Ask again" --title="Answer to the question" --width=500 --height=400 --filename=<(echo  "${response//\\}")
        if [ "$?" != 0 ]
        then
          exit
        fi

    fi
fi

while [ 1 ]
  do
    previous_question="$text"
    text=$(zenity --text-info --ok-label="Ask again" --title="Ask again" --editable --text="Enter your question text:")
    if [ "$?" != 0 ]
    then
        exit
    fi
    response="$(get_response_no_pic "Answer the new question in a brief but precise way taking in mind the context of the last conversation. This is the last question: $text. This is the answer you gave to it: $response.
    The new question is: $text.")"
    zenity --text-info --ok-label="Ask again" --title="Answer to the question" --width=500 --height=400 --filename=<(echo  "${response//\\}")
    if [ "$?" != 0 ]
    then
      exit
    fi
  done
