# heatit

HEATIT - Hashing EvAluation ToolkIT

## Usage

Supported hashing methods:

`AGH, BRE, CH, CPH, DSH, IsoH, ITQ, KLSH, LSH, SH, SpH, USPLH`

You can get the following curves drawn by the Hamming ranking method:

* Recall - the number of retrieved samples curves
* Precision - the number of retrieved samples curves
* Precision - recall curves

### For GUI

* Download siftsmall.tar.gz, siftsmall.tar.gz and gist.tar.gz from [here](http://corpus-texmex.irisa.fr/).
* Extract the data set you want to use to the corresponding folder.
* Run `heatit.mlapp` using MATLAB App Designer.

### For CLI

* Download siftsmall.tar.gz, siftsmall.tar.gz and gist.tar.gz from [here](http://corpus-texmex.irisa.fr/).
* Extract the data set you want to use to the corresponding folder.
* Run `heatit.m`.
* You can choose different `datasetCandi`, `methodCandi`, `numberOfPoint` and `codelength` parameters. Modifying any code of `heatit.m` does not affect the behavior of `heatit.mlapp`.

## Screenshots

<p align="center"><img src="./img/interface.png" width="800"></p>

<p align="center"><img src="./img/drawing.png" width="800"></p>

## Hashing method interface

```matlab
% Offline training
function [model, train_coded, train_time] = method_learn(trainset, codelength)

% Online search (encoding only)
function [test_coded, test_time] = method_compress(testset, model)
```

## Datasets

[SIFT10K, SIFT1M and GIST1M](http://corpus-texmex.irisa.fr/)

## License

Heatit is licensed under the MIT License.
