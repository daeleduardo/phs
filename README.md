### PHS


É um prototipo de rendereização de página, tendo como parâmetro a possibilidade de fazer a validação no backend/frontend ou somente no backend.


#### Instruções de uso:

- O código foi feito em PHP 8.0 , e deve ser executado em um ambiente que possua esta versão disponível.


#### Exemplo de uso:

Pode-se acessar via terminal o diretório do projeto, e executar um serviço de servidor do PHP:

`php -S 0.0.0.0:8082 -t .`

Pode-se chamar a URL no navegador de duas formas:

Sem passar nenhum parâmetro: 

`http://0.0.0.0:8082/`

Também pode-se passar o parâmetro *validadescript* que é um booleano que ativa ou não a validação do formulário na interface via javascript (caso esse parâmetro não seja informado, será processado o valor padrão que é "falso."): 

`0.0.0.0:8082/index.php?validadescript=1`

A validações que ocorrem no backend e no frontend (este último caso seja ativado), são:

- Data: deverá ser um campo de data no seguinte formato mm-dd-YYYY
 - Texto: O texto só deverá possuir letras minúsculas e espaços, até 144 chars.
 - Texto grande: O texto só deverá possuir letras maiúsculas, números e 
espaços até 255 chars


As mensagem de erro oriundas do frontend irão aparece na tela em forma de pop, as validações oriundas do backend irão aparecer abaixo do formulário em vermelho.




### Banco de dados:

Para o banco de dados criado em SQL Server, há os seguintes scripts:
* Criar o banco de dados e suas estruturas:
`01_create.sql`
* Executar os testes (procedure de inserção, atualização e visualização dos dados):
`02_test.sql`





