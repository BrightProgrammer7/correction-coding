function decoded_bit = decodeHard(decoded_bit)

H = [0 0 0 1 1 1 1; 
     0 1 1 0 0 1 1; 
     1 0 1 0 1 0 1];

[rows, info_word_length] = size(decoded_bit);
       for l = 1:info_word_length
%HARD Decoding
        hi= mod(H*decoded_bit(:,l),2)   ;       %Syndrome Detection
        for j=1:rows               %Matching 'hi' to every row vector of H and flipping the corresponding bit of 'z' using xor
            if (hi==H(:,j))
                pos = bin2dec(num2str(hi'));
                 column_vector = zeros(7, 1);
                 column_vector(pos) = 1;
    decoded_bit(:, l) = mod(decoded_bit(:, l) +column_vector, 2);        
            end
        end
       end
end

