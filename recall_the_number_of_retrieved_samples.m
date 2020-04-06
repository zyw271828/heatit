addpath(genpath('./'))

% datasetCandi = {'siftsmall', 'sift', 'gist'};
datasetCandi = {'siftsmall'};

% methodCandi = {'AGH1', 'AGH2', 'BRE', 'CH', 'CPH', 'DSH', 'IsoH', 'ITQ', 'KLSH', 'LSH', 'SH', 'SpH', 'USPLH'};
methodCandi = {'LSH', 'SpH'};

% the number of retrieved samples increments from 0 to length(trainset) in step incrementalStep
incrementalStep = 100;

% code length used for training
codelength = 64;

for d = 1:length(datasetCandi)
    dataset = datasetCandi{d};

    % read trainset, testset and groundtruthset
    trainset = double(fvecs_read(['./dataset/', dataset, '/', dataset, '_base.fvecs']));
    trainset = trainset';
    testset = fvecs_read(['./dataset/', dataset, '/', dataset, '_query.fvecs']);
    testset = testset';
    groundtruthset = ivecs_read(['./dataset/', dataset, '/', dataset, '_groundtruth.ivecs']);
    groundtruthset = groundtruthset';

    for m = 1:length(methodCandi)
        method = methodCandi{m};
        % used to draw curves
        the_number_of_retrieved_samples_vector = (0:incrementalStep:length(trainset));
        % the_number_of_retrieved_samples_vector = (0:incrementalStep:length(groundtruthset)); % debug
        recall_vector = Inf(1, length(the_number_of_retrieved_samples_vector));

        disp('==============================');
        disp([num2str(codelength), '-bits ', method, ' on ', dataset]);
        disp('------------------------------');

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
        for n = 1:length(the_number_of_retrieved_samples_vector)
            number_retrieved = the_number_of_retrieved_samples_vector(n);

            recall_sum = 0; % used to calculate average recall

            for ii = 1:size(testB, 1)

                res = Inf(length(trainB), 2);

                for jj = 1:size(trainB, 1)
                    res(jj, 1) = jj;
                    res(jj, 2) = hammingDist(testB(ii, :), trainB(jj, :));
                end

                res = sortrows(res, 2); % sort by hamming distance
                res = res(1:number_retrieved, :);

                % disp(['Query number: ', num2str(ii)])
                % groundtruthset data is numbered from 0
                recall = length(intersect(res(:, 1), groundtruthset(ii, :)' + 1)) / length(groundtruthset);
                recall_sum = recall_sum + recall;
                % disp([method, ' number retrieved: ', num2str(number_retrieved)])
                % disp(['recall: ', num2str(recall)])
                % disp(res);
            end

            average_recall = recall_sum / length(groundtruthset);
            disp(['Average recall: ', num2str(average_recall)]);
            recall_vector(n) = average_recall;

            % 68-95-99.7 rule
            if average_recall >= 0.997
                disp(['break, number_retrieved is ', num2str(number_retrieved)]);
                break
            end

        end

        plot(the_number_of_retrieved_samples_vector, recall_vector, '-*');
        hold on;
    end

    legend(methodCandi, 'Location', 'southeast');
    title(['Recall - the number of retrieved samples curves on ', dataset, ' dataset'])
    xlabel('The number of retrieved samples');
    ylabel('Recall');
    hold off;
end
