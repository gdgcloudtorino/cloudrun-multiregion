# To run this code you need to install the following dependencies:
# pip install google-genai
import argparse
import base64
import mimetypes
import os
from google import genai
from google.genai import types
from google.cloud import storage
from google.cloud.exceptions import NotFound


def upload_to_gcs(bucket_name, image, blob_name):
    """
    Uploads a generated image to a Google Cloud Storage bucket.
    """
    try:
        # The image data is in a BytesIO wrapper, access it with _image_bytes
        image_bytes = image
        
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        
        # Create the bucket if it does not exist
        if not bucket.exists():
            print(f"Bucket {bucket_name} not found. Creating it in europe-west8...")
            try:
                storage_client.create_bucket(bucket, location="europe-west8")
                print(f"Bucket {bucket_name} created successfully.")
            except Exception as e:
                print(f"Error creating bucket: {e}")
                sys.exit(1)


        blob = bucket.blob(blob_name)

        print(f"Uploading image to gs://{bucket_name}/{blob_name}...")
        blob.upload_from_string(image_bytes, content_type="image/jpeg")
        print(f"Successfully uploaded {blob_name}.")

    except Exception as e:
        print(f"Error uploading to GCS: {e}")

def generate(args):
    client = genai.Client(
        api_key=os.environ.get("GEMINI_API_KEY"),
    )

    model = "gemini-2.5-flash-image-preview"
    contents = [
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text=args.prompt),
            ],
        ),
    ]
    generate_content_config = types.GenerateContentConfig(
        response_modalities=[
            "IMAGE",
            "TEXT",
        ],
    )

    file_index = 0
    for chunk in client.models.generate_content_stream(
        model=model,
        contents=contents,
        config=generate_content_config,
    ):
        if (
            chunk.candidates is None
            or chunk.candidates[0].content is None
            or chunk.candidates[0].content.parts is None
        ):
            continue
        if chunk.candidates[0].content.parts[0].inline_data and chunk.candidates[0].content.parts[0].inline_data.data:
            inline_data = chunk.candidates[0].content.parts[0].inline_data
            img = inline_data.data
            bucket_name = args.project_id
            filename = args.output
            upload_to_gcs(bucket_name, img, filename)   
        else:
            print(chunk.text)



def main():
    """
    Main function to generate and upload images.
    """
    parser = argparse.ArgumentParser(description="Generate images and upload to GCS.")
    parser.add_argument("project_id", help="Your Google Cloud Project ID.")
    parser.add_argument("prompt", help="The prompt to generate the images")
    parser.add_argument("output", help="The GCS destination object")
    args = parser.parse_args()    
    generated_image = generate(args)
    print("\nScript finished.")


if __name__ == "__main__":
    main()
## example
## python geneate_with_gemini.py --project_id=$(gcloud config get-value project) --prompt="Cloud Run in Modena" --output="test/test_1.jpeg"