import os
import smtplib
import json
from email.mime.text import MIMEText
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Configuration
FOLDER_ID = "1-UOXB00K6959CZZNLQn2CI5YdjzZr6sX"
SCOPES = ['https://www.googleapis.com/auth/drive']

def get_service():
    creds = None
    # token.json stores your actual login session
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            # This handles the "web" type JSON you just provided
            flow = InstalledAppFlow.from_client_secrets_file(
                'creds.json', 
                scopes=SCOPES,
                redirect_uri='http://localhost:8080/'
            )
            creds = flow.run_local_server(port=8080)
        
        with open('token.json', 'w') as token:
            token.write(creds.to_json())

    return build('drive', 'v3', credentials=creds)

def main():
    service = get_service()
    ref_name = os.environ.get('GITHUB_REF_NAME', 'Local-Dev')
    
    # Update these paths to match your local folder structure
    apk_files = [
        'build/app/outputs/flutter-apk/tikgood-v7-arm64.apk',
        'build/app/outputs/flutter-apk/tikgood-v7-x64.apk',
        'build/app/outputs/flutter-apk/tikgood-v8-arm64.apk',
        'build/app/outputs/flutter-apk/tikgood-v8-x64.apk',
    ]

    links = []
    for apk_path in apk_files:
        if not os.path.exists(apk_path):
            print(f"File missing: {apk_path}")
            continue

        file_name = os.path.basename(apk_path)
        print(f"Uploading {file_name}...")

        file_metadata = {'name': file_name, 'parents': [FOLDER_ID]}
        media = MediaFileUpload(
            apk_path, 
            mimetype='application/vnd.android.package-archive', 
            resumable=True
        )
        
        request = service.files().create(
            body=file_metadata, 
            media_body=media, 
            fields='id,webViewLink'
        )
        
        response = None
        while response is None:
            status, response = request.next_chunk()
            if status:
                print(f"Progress: {int(status.progress() * 100)}%")

        # Make public
        service.permissions().create(
            fileId=response['id'],
            body={'type': 'anyone', 'role': 'reader'}
        ).execute()

        links.append(f"{file_name}: {response['webViewLink']}")

    # Email
    if links:
        try:
            user = os.environ.get('EMAIL_USER')
            pw = os.environ.get('EMAIL_PASS')
            receiver = os.environ.get('EMAIL_RECEIVER')
            
            if user and pw:
                body = f"TikGood Build\n\n" + "\n".join(links)
                msg = MIMEText(body)
                msg['Subject'] = f'TikGood APKs - {ref_name}'
                msg['From'], msg['To'] = user, receiver
                with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
                    smtp.login(user, pw)
                    smtp.send_message(msg)
                print("Email sent!")
        except Exception as e:
            print(f"Email failed: {e}")

    print("\nDone! Links:\n" + "\n".join(links))

if __name__ == '__main__':
    main()