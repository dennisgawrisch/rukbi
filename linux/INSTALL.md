Installing Rukbi
================

Run `install/install` as a superuser:

```bash
sudo install/install
```

This script should take care of installation. In case of problems, provide the path to the XKB directory explicity:

```bash
sudo install/install -d /usr/local/X11/xkb
```

Removing Rukbi
==============

An automated tool to remove Rukbi is not provided. You have to remove Rukbi files manually from the XKB directory
(usually `/usr/share/X11/xkb` or `/etc/X11/xkb`; look for `rukbi_*` files in the `symbols` subdirectory). After that,
you have to remove code fragments that were added to the lists of the layouts (`*.lst` and `*.xml` files in the `rules`
subdirectory).

Configuration
=============

Normally, you would select a layout in your environment’s keyboard/input/language settings. Try searching by language:
Russian, English etc.

If you need to specify the name of the layout (and its variant) manually, use the following:

| rukbi_ru      | Russian                |
| rukbi_ru(ukr) | Russian with Ukrainian |
| rukbi_uk      | Ukrainian              |
| rukbi_uk(rus) | Ukrainian with Russian |
| rukbi_en      | English                |
| rukbi_en(deu) | English with German    |
| rukbi_de      | German                 |
