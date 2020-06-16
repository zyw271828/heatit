addpath(genpath('./'))

% datasetCandi = {'siftsmall', 'sift', 'gist'};
datasetCandi = {'siftsmall'};

% methodCandi = {'AGH1', 'AGH2', 'BRE', 'CH', 'CPH', 'DSH', 'IsoH', 'ITQ', 'KLSH', 'LSH', 'SH', 'SpH', 'USPLH'};
methodCandi = {'LSH', 'SpH'};

% the number of retrieved samples vector is round(logspace(0, log10(length(trainset)), numberOfPoint))
numberOfPoint = 20;

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

    % create tiled chart layout, introduced in R2019b
    t = tiledlayout(1, 3);
    title(t, [num2str(codelength), '-bits code length on ', dataset, ' dataset']);

    for m = 1:length(methodCandi)
        method = methodCandi{m};
        the_number_of_retrieved_samples_vector = round(logspace(0, log10(length(trainset)), numberOfPoint));
        % the_number_of_retrieved_samples_vector = (0:1000:length(trainset)); % debug

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
            % if average_recall >= 0.997
            if average_recall >= 1
                disp(['break, number_retrieved is ', num2str(number_retrieved)]);
                break
            end

        end

        ax1 = nexttile(1);
        plot(ax1, the_number_of_retrieved_samples_vector, recall_vector, '-*');
        hold(ax1, 'on');

        ax2 = nexttile(2);
        plot(ax2, the_number_of_retrieved_samples_vector, precision_vector, '-*');
        hold(ax2, 'on');

        ax3 = nexttile(3);
        plot(ax3, recall_vector, precision_vector, '-*');
        hold(ax3, 'on');
    end

    % add title and axis labels to chart
    legend(ax1, methodCandi, 'Location', 'southeast');
    title(ax1, 'Recall - the number of retrieved samples curves');
    xlabel(ax1, 'The number of retrieved samples');
    ylabel(ax1, 'Recall');
    hold(ax1, 'off');

    legend(ax2, methodCandi, 'Location', 'northeast');
    title(ax2, 'Precision - the number of retrieved samples curves');
    xlabel(ax2, 'The number of retrieved samples');
    ylabel(ax2, 'Precision');
    hold(ax2, 'off');

    legend(ax3, methodCandi, 'Location', 'northeast');
    title(ax3, 'Precision - recall curves');
    xlabel(ax3, 'Recall');
    ylabel(ax3, 'Precision');
    hold(ax3, 'off');
end
