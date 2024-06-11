function code_word = encode7_4(info_word)
    % Calcul des bits de parité
    code_bit5 = xor(info_word(1,:),xor(info_word(2,:),info_word(4,:))); % Premier bit de parité
    code_bit6 = xor(info_word(1,:),xor(info_word(3,:),info_word(4,:))); % Deuxième bit de parité
    code_bit7 = xor(info_word(2,:),xor(info_word(3,:),info_word(4,:))); % Troisième bit de parité
    
    % Concaténation des données et des bits de parité
    code_word = [code_bit5; code_bit6; info_word(1,:); code_bit7; info_word(2:4,:)];     
end
