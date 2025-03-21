# Raster.ai

**シンプルなプロンプトからはじめて、思い通りの画像を生成しよう。**
[![Codemagic build status](https://api.codemagic.io/apps/67dbdd63f2be6be8cf5fc8af/67dbdd63f2be6be8cf5fc8ae/status_badge.svg)](https://codemagic.io/app/67dbdd63f2be6be8cf5fc8af/67dbdd63f2be6be8cf5fc8ae/latest_build)

[Progateハッカソン powered by AWS 2025.03](https://progate.connpass.com/event/342402/) 提出作品

## プロダクト概要
AIエージェントを使った画像生成サービス。
従来の画像生成AIでは、複雑なプロンプトを使わなければ思った通りの画像を生成することができませんでした。  
また、マイナーなある特定の商品などの**固有名詞を含むプロンプトを入力しても、画像生成モデルが未学習で生成できない**といった問題がありました。

このサービスでは、**LLMがユーザが生成したい画像の内容を対話から汲み取り、画像生成モデルのプロンプトを試行錯誤しながらチューニング**することで、
画像生成モデルが未学習の概念を含む画像も出力できることを目指します。

「LLMは理解してくれてるけど、生成画像には全然反映されない！」というもどかしさをこのサービスが解決します。