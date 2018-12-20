- predictしたデータをゲーム用に変換する
  - process_poly.ipynbの下の方にあります
  - movie_mask_250.jsonが変換できるはず

- via-viaのjson(annotated)を学習用に変換する
  - process_poly.ipynbの上の方にあったはず

- 動画を切り出す
  - ffmpeg入れて
  - `ffmpeg -i video.mp4 -vcodec png -r 10 ./VID_cropped/image_%03d.png`
  - 10 frame/s のレートで画像に変換されます
  - rオプション抜きだとそのままのレート