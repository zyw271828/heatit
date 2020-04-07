addpath(genpath('./'))

% datasetCandi = {'siftsmall', 'sift', 'gist'};
datasetCandi = {'siftsmall'};

% methodCandi = {'AGH1', 'AGH2', 'BRE', 'CH', 'CPH', 'DSH', 'IsoH', 'ITQ', 'KLSH', 'LSH', 'SH', 'SpH', 'USPLH'};
methodCandi = {'LSH'};

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
        the_number_of_retrieved_samples_vector = (0:incrementalStep:length(trainset));
        % the_number_of_retrieved_samples_vector = (0:incrementalStep:length(groundtruthset)); % debug

        % used to draw curves
        recall_vector = Inf(1, length(the_number_of_retrieved_samples_vector));
        precision_vector = Inf(1, length(the_number_of_retrieved_samples_vector));

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
            precision_sum = 0; % used to calculate average precision

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
                precision = length(intersect(res(:, 1), groundtruthset(ii, :)' + 1)) / number_retrieved;
                precision_sum = precision_sum + precision;
                % disp([method, ' number retrieved: ', num2str(number_retrieved)])
                % disp(['recall: ', num2str(recall)])
                % disp(res);
            end

            average_recall = recall_sum / length(groundtruthset);
            disp(['Average recall: ', num2str(average_recall)]);
            recall_vector(n) = average_recall;

            average_precision = precision_sum / length(groundtruthset);
            disp(['Average precision: ', num2str(average_precision)]);
            precision_vector(n) = average_precision;

            % 68-95-99.7 rule
            if average_recall >= 0.997
                disp(['break, number_retrieved is ', num2str(number_retrieved)]);
                break
            end

        end

        % create tiled chart layout, introduced in R2019b
        % FIXME: Cannot draw curves for multiple methods
        t = tiledlayout(1, 3);
        title(t, [num2str(codelength), '-bits code length on ', dataset, ' dataset'])

        nexttile(1);
        plot(the_number_of_retrieved_samples_vector, recall_vector, '-*');
        hold on;

        nexttile(2);
        plot(the_number_of_retrieved_samples_vector, precision_vector, '-*');
        hold on;

        nexttile(3);
        plot(recall_vector, precision_vector, '-*');
        hold on;
    end

    nexttile(1);
    legend(methodCandi, 'Location', 'southeast');
    title('Recall - the number of retrieved samples curves')
    xlabel('The number of retrieved samples');
    ylabel('Recall');
    hold off;

    nexttile(2);
    legend(methodCandi, 'Location', 'northeast');
    title('Precision - the number of retrieved samples curves')
    xlabel('The number of retrieved samples');
    ylabel('Precision');
    hold off;

    nexttile(3);
    legend(methodCandi, 'Location', 'southwest');
    title('Precision - recall curves')
    xlabel('Recall');
    ylabel('Precision');
    hold off;
end
