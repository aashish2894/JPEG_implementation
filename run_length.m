function [ lookup_t ] = run_length( Y_Q )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
eob_i = 1;   % end of block index i
eob_j = 2;   % end of block index j
z_j = 0;
i = 8;
j = 8;
itr = 1;
flag1 = 0;
flag2 = 0;
flag3 = 0;
Y_Zigzag = zeros(1,64);
lookup_t = zeros(1,3); % will contain the numbers in run,length,value format
% find upto what index zig-zag scan should be done,i.e., after
% which there will be only zeros
% e0b_i and eob_j will store the indices
while(itr>=1 && flag1 == 0)
    if i==1 || i==8
        j = j-1;
        %flag2 = 0;
        if Y_Q(i,j)~=0
            flag1 = 1;
            eob_i = i;
            eob_j = j+1;
            break;
        end
    else   
         i = i-1;
         %flag2 = 1;
         if Y_Q(i,j)~=0
              flag1 = 1;
              eob_i = i+1;
              eob_j = j;
              break;
         end
    end
    if flag1==0
        if flag2==0
            for k = 1:itr
                i = i-1;
                j = j+1;
                if Y_Q(i,j)~=0
                    flag1 = 1;
                    eob_i = i+1;
                    eob_j = j-1;
                    break;
                 end
             end
         else
              for k = 1:itr
                  i = i+1;
                  j = j-1;
                  if Y_Q(i,j)~=0
                      flag1 = 1;
                      eob_i = i-1;
                      eob_j = j+1;
                      break;
                  end
              end
        end
    end
    if itr==7
        flag3 = 1;
    end
    if flag3==1
        itr = itr-1;
    else
        itr = itr+1;
    end
    if flag2==1
         flag2=0;
    else
         flag2=1;
    end
end
i = 1;
j = 1;
itr = 1;
flag1 = 0;
flag2 = 0;
flag3 = 0;
% Zig-zag scan
while(itr>=1 && flag1==0)
    if i==1 || i==8
        j = j+1;
        %flag2 = 0;
        if i==eob_i && j==eob_j
            flag1 =1;
            break;
        end
        z_j = z_j + 1;
        Y_Zigzag(1,z_j) = Y_Q(i,j);
    else
        i = i+1;
        if i==eob_i && j==eob_j
            flag1 = 1;
            break;
        end
        z_j = z_j + 1;
        Y_Zigzag(1,z_j) = Y_Q(i,j);
        %flag2 = 1;
    end
    if flag1==0
    if flag2 == 0
        for k = 1:itr
            z_j = z_j + 1;
            i = i+1;
            j = j-1;
            if i==eob_i && j==eob_j
                flag1 = 1;
                break;
            end
            Y_Zigzag(1,z_j) = Y_Q(i,j);
        end
    else
        for k = 1:itr
            z_j = z_j + 1;
            i = i-1;
            j = j+1;
            if i==eob_i && j==eob_j
                flag1 = 1;
                break;
            end
            Y_Zigzag(1,z_j) = Y_Q(i,j);
        end
    end
    end
    if itr==7
        flag3 = 1;
    end
    if flag3 == 1
        itr = itr - 1;
    else
        itr = itr + 1;
    end
    if flag2 == 1
        flag2 = 0;
    else
        flag2 = 1;
    end
end
l_i = 0;
count = 0;
% lookup_t  - first column stores the number of zeros, second column the
% length of binary number, third column stores the element
% having this (run,length)
for i = 1:z_j-1
    bin_num = de2bi(abs(Y_Zigzag(1,i)));
    [~,size_bin] = size(bin_num); 
    if Y_Zigzag(1,i)==0
        count = count + 1;
    else
        l_i = l_i + 1;
        lookup_t(l_i,1) = count;
        lookup_t(l_i,2) = size_bin;
        lookup_t(l_i,3) = Y_Zigzag(1,i);
    end
end
end

