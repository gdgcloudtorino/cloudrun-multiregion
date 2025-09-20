
import argparse
import base64
import datetime
import sys

from google.cloud import aiplatform
from google.cloud import storage
from google.cloud.exceptions import NotFound

def generate_images(project_id, location="us-central1"):
    """
    Generates four images of a banana using a Vertex AI image generation model.
    """
    print(f"Initializing Vertex AI for project {project_id} in {location}...")
    aiplatform.init(project=project_id, location=location)

    # Load the image generation model
    model = aiplatform.ImageGenerationModel.from_pretrained("imagegeneration@006")

    print("Generating 4 images of a banana...")
    try:
        images = model.generate_images(
            prompt="some meme image abount Cloud Run and Modena. Include some typical Modena place or dishes",
            number_of_images=4,
        )
        print("Successfully generated images.")
        return images
    except Exception as e:
        print(f"Error generating images: {e}")
        sys.exit(1)


def upload_to_gcs(bucket_name, image, blob_name):
    """
    Uploads a generated image to a Google Cloud Storage bucket.
    """
    try:
        # The image data is in a BytesIO wrapper, access it with _image_bytes
        image_bytes = image._image_bytes
        
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        
        # Create the bucket if it does not exist
        if not bucket.exists():
            print(f"Bucket {bucket_name} not found. Creating it in us-central1...")
            try:
                storage_client.create_bucket(bucket, location="us-central1")
                print(f"Bucket {bucket_name} created successfully.")
            except Exception as e:
                print(f"Error creating bucket: {e}")
                sys.exit(1)


        blob = bucket.blob(blob_name)

        print(f"Uploading image to gs://{bucket_name}/{blob_name}...")
        blob.upload_from_string(image_bytes, content_type="image/png")
        print(f"Successfully uploaded {blob_name}.")

    except Exception as e:
        print(f"Error uploading to GCS: {e}")


def main():
    """
    Main function to generate and upload images.
    """
    parser = argparse.ArgumentParser(description="Generate banana images and upload to GCS.")
    parser.add_argument("project_id", help="Your Google Cloud Project ID.")
    args = parser.parse_args()

    bucket_name = args.project_id
    generated_images = generate_images(project_id=args.project_id)

    if generated_images:
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        for i, img in enumerate(generated_images):
            filename = f"banana_{timestamp}_{i+1}.png"
            upload_to_gcs(bucket_name, img, filename)
    
    print("\nScript finished.")


if __name__ == "__main__":
    main()
