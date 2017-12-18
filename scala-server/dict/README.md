
## Dictionary Directorory for Word Game

The program recognizes a file named `<local-code>-words.txt` in this
directory as a word list for the language designated by _local-code_.

To allow experimentation with different dictionaries, `<local-code>-words.txt`
is usually a symbolic link to the actual word list file.

For example, to use the English spell checker dictionary on unix-based platforms
link as follows: 

    `ln -s /usr/share/dict/words en-words.txt`

- moby-english.txt - 
    
    Derived from word list file mwords/354984si.ngl of the 
    Moby project - http://icon.shef.ac.uk/Moby/. Convert eols and 
    remove special characters.
    
      `dos2unix 354984si.ngl`
      `egrep "^[a-zA-Z]+$" 354984si.ngl > moby-english.txt 



