
## Dictionary Directorory for Word Game

The program recognizes a file named `<local-code>-words.txt` in this
directory as a word list for the language designated by _local-code_.

To allow experimentation with different dictionaries, `<local-code>-words.txt`
is usually a symbolic link to the actual word list file.

For example, to use the English spell checker dictionary on unix-based platforms
link as follows: 

    `ln -s /usr/share/dict/words en-words.txt`

- moby-english.txt - 
    
    Derived from CROSSWD.TXT of the project Gutenberg Moby free ebook: 
    http://www.gutenberg.org/files/3201/3201.txt
    http://www.gutenberg.org/files/3201/files/CROSSWD.TXT.
      
      `dos2unix CROSSWD.TXT`

    Note other files in the ebook may contain special characters. If you 
    decide to use them, remove the words with special characters:
    
      `egrep "^[a-zA-Z]+$" file 



