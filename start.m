addpath(genpath('./'))

datasetCandi = {'siftsmall'};
% datasetCandi = {'siftsmall', 'sift', 'gist'};

methodCandi = {'LSH'};
% methodCandi = {'AGH1', 'AGH2', 'BRE', 'CH', 'CPH', 'DSH', 'IsoH', 'ITQ', 'KLSH', 'LSH', 'SH', 'SpH', 'USPLH'};

codelengthCandi = [1024];
% codelengthCandi = [32, 64, 128, 256, 512, 1024];

for d = 1:length(datasetCandi)
    dataset = datasetCandi{d};

    for m = 1:length(methodCandi)
        method = methodCandi{m};

        for c = 1:length(codelengthCandi)
            codelength = codelengthCandi(c);

            % ResultFile = ['./result/', dataset, '/hashingCodeLong.', num2str(codelength), '/', method, 'table', upper(dataset), '32b_1'];
            % bFound = checkFILEmkDIR(ResultFile);
            %
            % if (bFound)
            %     error('Result file exists!');
            % end

            disp('==============================');
            disp([method, ' ', num2str(codelength), 'bit ', dataset]);
            disp('==============================');

            trainset = double(fvecs_read(['./dataset/', dataset, '/', dataset, '_base.fvecs']));
            testset = fvecs_read(['./dataset/', dataset, '/', dataset, '_query.fvecs']);
            trainset = trainset';
            testset = testset';

            trainStr = ['[model, trainB, train_elapse] = ', method, '_learn(trainset, codelength);'];
            testStr = ['[testB, test_elapse] = ', method, '_compress(testset, model);'];
            eval(trainStr);
            eval(testStr);

            ntrain = size(trainB, 1);
            ntest = size(testB, 1);

            realcodelength = size(trainB, 2);
            disp([method, ' ', num2str(realcodelength), 'bit learned.', dataset]);
            disp('==============================');
            disp(['Total training time: ', num2str(train_elapse)]);
            disp(['Total test time: ', num2str(test_elapse)]);

            % start searching
            groundtruthset = ivecs_read(['./dataset/', dataset, '/', dataset, '_groundtruth.ivecs']);
            groundtruthset = groundtruthset';

            tmp_T = tic;

            for ii = 1:size(testB, 1)

                res = Inf(length(groundtruthset) + 1, 2);

                for jj = 1:size(trainB, 1)
                    res(length(groundtruthset) + 1, 1) = jj;
                    res(length(groundtruthset) + 1, 2) = hammingDist(testB(ii, :), trainB(jj, :));
                    res = sortrows(res, 2); % sort by hamming distance
                end

                res(end, :) = [];
                disp(['Query number: ', num2str(ii)])
                % groundtruthset data is numbered from 0
                recall = length(union(res(:, 1), groundtruthset(ii, :)' + 1)) / length(groundtruthset);
                disp(['recall: ', num2str(recall)])
                % disp(res);
                disp('==============================');
            end

            search_elapse = toc(tmp_T);
            disp(['Total search time (', num2str(codelength), '-bits ', method, '): ', num2str(search_elapse)]);

        end

    end

end
