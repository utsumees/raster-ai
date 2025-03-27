import flet as ft
import boto3
import os
from dotenv import load_dotenv
import asyncio
from datetime import datetime, timezone

# 環境変数のロード（AWSの認証情報を設定）
load_dotenv()
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY")
BUCKET_NAME = "tora-generated-images"

# S3 クライアントの設定
s3 = boto3.client(
    "s3", aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY
)


def get_latest_images(limit=6, since: datetime = None):
    """S3 バケットから最新の画像を取得（since 以降）"""
    response = s3.list_objects_v2(Bucket=BUCKET_NAME)
    if "Contents" not in response:
        return []

    # 更新日時でソート
    images = sorted(response["Contents"], key=lambda x: x["LastModified"], reverse=True)
    # アプリ起動以降の画像のみ
    if since:
        images = [img for img in images if img["LastModified"] > since]

    image_urls = [
        f"https://{BUCKET_NAME}.s3.amazonaws.com/{img['Key']}"
        for img in images
        if img["Key"].lower().endswith((".png", ".jpg", ".jpeg"))
    ][:limit]

    return image_urls


async def main(page: ft.Page):
    page.title = "S3 Image Viewer"
    page.padding = 20

    image_container = ft.Row(spacing=10, wrap=True)
    # アプリ起動時刻を記録（UTC）
    app_start_time = datetime.now(timezone.utc)

    async def update_images():
        """最新の画像を取得し画面を更新"""
        image_urls = get_latest_images(since=app_start_time)
        image_container.controls.clear()
        for url in image_urls:
            image_container.controls.append(ft.Image(src=url, width=300, height=300))
        page.update()

    async def periodic_update():
        """一定間隔で画像を更新"""
        while True:
            await update_images()
            await asyncio.sleep(5)  # 5秒間隔で更新

    page.controls.append(image_container)
    page.update()

    # 非同期タスクの開始（実行中のイベントループでタスクを作成）
    asyncio.create_task(periodic_update())


ft.app(target=main)
