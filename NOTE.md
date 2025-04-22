


### 參考

- https://github.com/google/mdbook-i18n-helpers
- https://github.com/google/comprehensive-rust

```bash
git clone --depth=1 https://github.com/rust-lang/mdBook.git
cd mdBook
cd guide

# 建置 en 原文
mdbook build . --dest-dir book/en
```

在 `book.toml` 中新增：

```toml
[preprocessor.gettext]
after = ["links"]
```


```bash
MDBOOK_OUTPUT='{"xgettext": {}}' mdbook build -d po
MDBOOK_OUTPUT='{"xgettext": {"depth": 1}}' mdbook build -d po
MDBOOK_OUTPUT='{"xgettext": {"depth": 5}}' mdbook build -d po
# MDBOOK_OUTPUT='{"xgettext": {"granularity": 1}}' mdbook build -d po

msgcat --lang zh_TW --width 79 --output-file po/zh_TW.po po/messages.pot
msgmerge --lang zh_TW --width 79 --backup off --update --force-po --no-fuzzy-matching po/zh_TW.po po/messages.pot

MDBOOK_BOOK__LANGUAGE=zh_TW mdbook build -d book/zh_TW
```

```bash
MDBOOK_OUTPUT='{"xgettext": {}}' mdbook build -d locale
msgcat --lang zh_TW --width 79 --output-file locale/zh_TW.po locale/messages.pot
msgmerge --lang zh_TW --width 79 --backup off --update --force-po --no-fuzzy-matching locale/zh_TW.po locale/messages.pot
MDBOOK_BOOK__LANGUAGE=zh_TW mdbook build -d book/zh_TW
```

```toml
[preprocessor.gettext]
after = ["links"]
po-dir = "locale"
```



### 我的構思

先透過以下命令生成 `.pot` 檔案至 `locale/pot/` 目錄下：

```bash
MDBOOK_OUTPUT='{"xgettext": {"depth": 5}}' mdbook build -d locale/pot
```

接著透過命令稿批次執行 `msgcat` 或 `msgmerge` 命令將 `locale/pot` 目錄下的 `locale/<locale>`：

