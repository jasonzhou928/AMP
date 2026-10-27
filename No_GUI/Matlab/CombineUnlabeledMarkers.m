function markerDict = CombineUnlabeledMarkers(markerDict,verbose)
if nargin < 2
    verbose = true;
end
if verbose
    disp('%%%%%Combining Unlabeled Markers%%%%%')
end
markerStructnames = keys(markerDict);
if ~iscell(markerStructnames)
    markerStructnames = cellstr(markerStructnames);
end

markerSet = markerStructnames(contains(markerStructnames,'C_'));
nC = numel(markerSet);

if verbose
    disp(['Total Markers Before Combining: ',num2str(length(markerStructnames))])
end

if nC == 0
    if verbose
        disp(['Total Markers After Combining: ',num2str(length(keys(markerDict)))])
    end
    return
end

data = cell(nC,1);
intervals = cell(nC,1);
firstF = inf(nC,1);
lastF = -inf(nC,1);
alive = true(nC,1);

for i = 1:nC
    arr = markerDict({markerSet{i}});
    arr = arr{:};
    data{i} = arr;
    occ = ~isnan(arr(:,2));
    [st, en] = logicalRuns(occ);
    intervals{i} = [st, en];
    if ~isempty(st)
        firstF(i) = st(1);
        lastF(i) = en(end);
    else
        alive(i) = false;
    end
end

[~, order] = sort(firstF);
order = order(:)';
binIdx = zeros(nC,1);
nBins = 0;

for src = order
    if ~alive(src)
        continue
    end
    placed = false;
    for b = 1:nBins
        dst = binIdx(b);
        if lastF(dst) < firstF(src) || lastF(src) < firstF(dst) || ...
                ~intervalsOverlap(intervals{dst}, intervals{src})
            idx = ~isnan(data{src}(:,2));
            data{dst}(idx,2:4) = data{src}(idx,2:4);
            intervals{dst} = mergeIntervalSets(intervals{dst}, intervals{src});
            firstF(dst) = min(firstF(dst), firstF(src));
            lastF(dst) = max(lastF(dst), lastF(src));
            alive(src) = false;
            placed = true;
            break
        end
    end
    if ~placed
        nBins = nBins + 1;
        binIdx(nBins) = src;
    end
end

for i = 1:nC
    if alive(i)
        markerDict({markerSet{i}}) = {data{i}};
    else
        markerDict({markerSet{i}}) = [];
    end
end

if verbose
    disp(['Total Markers After Combining: ',num2str(length(keys(markerDict)))])
end
end

function [starts, ends] = logicalRuns(occ)
d = diff([false; occ(:); false]);
starts = find(d == 1);
ends = find(d == -1) - 1;
end

function tf = intervalsOverlap(A, B)
if isempty(A) || isempty(B)
    tf = false;
    return
end
i = 1;
j = 1;
nA = size(A,1);
nB = size(B,1);
while i <= nA && j <= nB
    if A(i,1) <= B(j,2) && B(j,1) <= A(i,2)
        tf = true;
        return
    end
    if A(i,2) < B(j,2)
        i = i + 1;
    else
        j = j + 1;
    end
end
tf = false;
end

function C = mergeIntervalSets(A, B)
if isempty(A)
    C = B;
    return
end
if isempty(B)
    C = A;
    return
end
M = sortrows([A; B], 1);
C = zeros(size(M,1), 2);
C(1,:) = M(1,:);
n = 1;
for k = 2:size(M,1)
    if M(k,1) <= C(n,2) + 1
        C(n,2) = max(C(n,2), M(k,2));
    else
        n = n + 1;
        C(n,:) = M(k,:);
    end
end
C = C(1:n,:);
end
