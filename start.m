addpath(genpath('./'))

datasetCandi = {'siftsmall'};
% datasetCandi = {'siftsmall', 'sift', 'gist'};

methodCandi = {'LSH', 'SpH'};
% methodCandi = {'AGH1', 'AGH2', 'BRE', 'CH', 'CPH', 'DSH', 'IsoH', 'ITQ', 'KLSH', 'LSH', 'SH', 'SpH', 'USPLH'};

codelengthCandi = [32, 64];
% codelengthCandi = [32, 64, 128, 256, 512, 1024];

for d = 1:length(datasetCandi)
    dataset = datasetCandi{d};

    for m = 1:length(methodCandi)
        method = methodCandi{m};

        for c = 1:length(codelengthCandi)
            codelength = codelengthCandi(c);

            disp('==============================');
            disp([num2str(codelength), '-bits ', method, ' on ', dataset]);
            disp('------------------------------');

            trainset = double(fvecs_read(['./dataset/', dataset, '/', dataset, '_base.fvecs']));
            testset = fvecs_read(['./dataset/', dataset, '/', dataset, '_query.fvecs']);
            trainset = trainset';
            testset = testset';

            % start training and testing
            trainStr = ['[model, trainB, train_elapse] = ', method, '_learn(trainset, codelength);'];
            testStr = ['[testB, test_elapse] = ', method, '_compress(testset, model);'];
            eval(trainStr);
            eval(testStr);

            ntrain = size(trainB, 1);
            ntest = size(testB, 1);

            realcodelength = size(trainB, 2);
            disp(['Total training time: ', num2str(train_elapse)]);
            disp(['Total test time: ', num2str(test_elapse)]);

            % start searching
            groundtruthset = ivecs_read(['./dataset/', dataset, '/', dataset, '_groundtruth.ivecs']);
            groundtruthset = groundtruthset';
            recall_sum = 0; % used to calculate average recall
            search_time_sum = 0;

            for ii = 1:size(testB, 1)

                res = Inf(length(groundtruthset) + 1, 2);
                tmp_T = tic;

                for jj = 1:size(trainB, 1)
                    res(length(groundtruthset) + 1, 1) = jj;
                    res(length(groundtruthset) + 1, 2) = hammingDist(testB(ii, :), trainB(jj, :));
                    res = sortrows(res, 2); % sort by hamming distance
                end

                res(end, :) = [];

                search_time = toc(tmp_T);
                search_time_sum = search_time_sum + search_time;

                % disp(['Query number: ', num2str(ii)])
                % groundtruthset data is numbered from 0
                recall = length(intersect(res(:, 1), groundtruthset(ii, :)' + 1)) / length(groundtruthset);
                recall_sum = recall_sum + recall;
                % disp(['recall: ', num2str(recall)])
                % disp(res);
            end

            disp(['Total search time: ', num2str(search_time_sum)]);
            disp(['Average recall: ', num2str(recall_sum / length(groundtruthset))]);
        end

    end

end
