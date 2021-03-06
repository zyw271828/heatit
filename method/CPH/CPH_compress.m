function [B, elapse] = CPH_compress(A, model)
    %   This is a wrapper function of CPH (Complmentary Projection Hashing) testing.
    %
    %	Usage:
    %	[B,elapse] = CPH_compress(A, model)
    %
    %	      A: Rows of vectors of data points. Each row is sample point
    %     model: The model generated by CPH_learn.
    %
    %	      B: The binary code of the input data A. Each row is sample point
    %    elapse: The coding time (testing time).
    %
    %	Zhongming Jin, Yao Hu, Yue Lin, Debing Zhang, Shiding Lin,
    %	Deng Cai, and Xuelong Li. Complmentary Projection Hashing. In
    %	ICCV 2013.
    %
    %
    %   version 2.0 --Nov/2016
    %   version 1.0 --Jan/2014
    %
    %   Written by Deng Cai (dengcai AT gmail DOT com)
    %

    tmp_T = tic;

    data = onlinekernelize(A, model.Landmarks, model.sigma);
    data = data - repmat(model.meandata, size(A, 1), 1);

    B = ((data * model.pj) > repmat(model.thres, size(A, 1), 1));

    elapse = toc(tmp_T);
end

function [K] = onlinekernelize(data, landmarks, sigma)
    d = EuDist2(data, landmarks);
    K = exp(-d.^2 ./ (sigma.^2));
end
