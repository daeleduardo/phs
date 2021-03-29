use contatos;
go
DECLARE
    @XMLV XML
DECLARE
    @XMLValue XML = '<?xml version="1.0"?>
 <Pessoa>
   <Registro>
     <idPessoa>1</idPessoa>
     <documento_cdTipo>0</documento_cdTipo>
     <documento_numero>999.999.999-95</documento_numero>
     <nome>Chatterjee333</nome>
     <razaoSocial>tarun1@abc.com</razaoSocial>
    <telefones>
         <Telefone principal="1">
         <numero>(99) 9987-0007</numero>
         </Telefone>
         <Telefone>
         <numero>(99) 99999-2222</numero>
         </Telefone>
    </telefones>
    <emails>
         <Email principal="1">
         <endereco>contato@empresa.com.br</endereco>
         </Email>
         <Email>
         <endereco>secundario@empresa.com.br</endereco>
         </Email>
    </emails>
    <dataNascimento>01/01/1990</dataNascimento>
    <dataFundacao>01/01/1990</dataFundacao>
    <website>tarun1@abc.com</website>
   </Registro>
 </Pessoa>'


/*teste insert*/
exec SPA_Pessoa_INSERT	@XMLValue , @XMLV output
SELECT @XMLV.query('Retorno') as Retorno
select * from Historico
/*teste update*/
exec SPA_Pessoa_UPDATE	@XMLValue , @XMLV output
select * from Historico
/*teste view*/
SELECT @XMLV.query('Retorno') as Retorno
select * from VE_Pessoa

