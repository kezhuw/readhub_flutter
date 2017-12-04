# Readhub Mobile App built with Flutter

A mobile app to taste [Flutter].

A [Flutter] project to taste mobile app development.

CAUTION: This is not a official app released from [Readhub][], just a experimental project to tasting [Flutter][].

DISCLAIMER: This project do not claims any proprietorship to assets, including but limited to logo, API from [Readhub][].

## Getting Started

For help getting started with Flutter, view online [documentation](http://flutter.io/).

Flutter evolves quickly, breaking API is likelihood to happen. This project is compatible with version 0.0.18.

## Known Issues

* API endpoints '/news' and '/technews' use timestamp as the sole cursor to paging data,
  if multiple entries with same timestamp exist, you may see duplicated news at page boundary
  in list view occasionally. I do encounter multiple news having same timestamp.
* The 'pull to refresh' functionality for endpoints '/news' and '/technews' merge newer news
  and old news, but if there is no conjunction between, old news are discarded. Thus, you may
  notice that 'more news' fetchs data you already viewed.

## TODO
- [ ] Refactor state Store.
- [ ] Preserve independent scroll position cross tabs.
- [ ] Refactor AppBar.
- [ ] Refine network error handling.

## License
Released under The MIT License (MIT). See [LICENSE](LICENSE) for the full license text.

## Contribution
Issues and pull requests are wecome. Also feel free to fork for your personal tasting.


[Readhub]: https://readhub.me/
[Flutter]: https://flutter.io/
