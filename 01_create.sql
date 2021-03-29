use tempdb;
go
drop database if exists contatos;
go
create database contatos;
go
use contatos;
go
create schema contatos;
go
-- auto-generated definition
create table Pessoa
(
    idPessoa         int identity
        constraint PK_Pessoa_1
            primary key,
    documento_cdTipo bit           not null,
    documento_numero nvarchar(18)  not null,
    nome             nvarchar(150) not null,
    razaoSocial      nvarchar(150),
    telefones        xml           not null,
    emails           xml           not null,
    dataNascimento   date,
    dataFundacao     date,
    website          nvarchar(300),
    DTINS            datetime      not null,
    DTALT            datetime
)
go

create table Historico
(
    idPessoa         int ,
    documento_cdTipo bit           not null,
    documento_numero nvarchar(18)  not null,
    nome             nvarchar(150) not null,
    razaoSocial      nvarchar(150),
    telefones        xml           not null,
    emails           xml           not null,
    dataNascimento   date,
    dataFundacao     date,
    website          nvarchar(300),
    DTINS            datetime      not null,
    CONSTRAINT FK_idPessoa FOREIGN KEY (idPessoa)
        REFERENCES contatos.dbo.Pessoa (idPessoa)
)
go


CREATE TRIGGER trg_ins_Pessoa
    ON contatos.dbo.Pessoa
    INSTEAD OF INSERT
    AS
BEGIN
    SET NOCOUNT ON;
    SELECT * INTO #inserted FROM inserted
    UPDATE #inserted SET DTINS = GETDATE() WHERE 1 = 1;
    INSERT contatos.dbo.Pessoa (documento_cdTipo, documento_numero, nome, razaoSocial, telefones, emails, dataNascimento,
                            dataFundacao, website, DTINS)
    SELECT i.documento_cdTipo,
           i.documento_numero,
           i.nome,
           i.razaoSocial,
           i.telefones,
           i.emails,
           i.dataNascimento,
           i.dataFundacao,
           i.website,
           GETDATE() as DTINS
    FROM #inserted i
END;
go

CREATE TRIGGER trg_upd_Pessoa
    ON contatos.dbo.Pessoa
    AFTER UPDATE
    AS
BEGIN
    SET NOCOUNT ON;
    UPDATE contatos.dbo.Pessoa
    SET DTALT = GETDATE()
    WHERE idPessoa IN (SELECT DISTINCT idPessoa FROM inserted)

    insert into contatos.dbo.Historico (
        idPessoa  ,
        documento_cdTipo ,
        documento_numero ,
        nome             ,
        razaoSocial      ,
        telefones        ,
        emails           ,
        dataNascimento   ,
        dataFundacao     ,
        website          ,
        DTINS
    ) select
          idPessoa  ,
          documento_cdTipo ,
          documento_numero ,
          nome             ,
          razaoSocial      ,
          telefones        ,
          emails           ,
          dataNascimento   ,
          dataFundacao     ,
          website          ,
          GETDATE() as DTINS from deleted

END;
go

CREATE PROCEDURE SPA_Pessoa_INSERT(@Campos XML, @Retorno XML OUTPUT)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @STATUS INT;
    DECLARE @MSG VARCHAR(255);
    DECLARE @BOOL BIT;
    DECLARE @TEMP_BOOL INT;

    BEGIN TRY

        /*valida se o campo documento_cdTipo é igual a 0 ou 1 */
        IF NOT EXISTS(SELECT 1
                      FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro)
                      WHERE Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') IN (0, 1))
            BEGIN
                SET @Retorno = (select 0 as status, 'Tipo de documento incorreto' as mensagem FOR XML PATH('Retorno'))
                return
            END

        /*valida se o campo documento_numero já existe na tabela Pessoa */
        IF EXISTS(
                SELECT 1
                FROM contatos.dbo.Pessoa
                WHERE documento_numero = (
                    SELECT Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)') AS documento_numero
                    FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
            )
            BEGIN
                SET @Retorno = (select 0 as status, 'Este documento já previamente cadastrado' as mensagem FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = (SELECT Pessoa.Registro.value('documento_cdTipo[1]', 'BIT')
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        /*valida se o campo documento_numero é um CPF válido se [documento_cdTipo] é 0 */
        IF @TEMP_BOOL = 0
            BEGIN
                SET @TEMP_BOOL = (SELECT PATINDEX('[0-9]%[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%', Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)'))
                                  FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'O CPF informado está incorreto' as mensagem FOR XML PATH('Retorno'))
                        return
                    END
            END

        /*valida se o campo documento_numero é um CNPJ válido se [documento_cdTipo] é 1 */
        IF @BOOL = 1
            BEGIN
                SET @TEMP_BOOL = (SELECT PATINDEX('[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%/[0-9]%[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%', Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)'))
                                  FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'O CNPJ informado está incorreto' as mensagem FOR XML PATH('Retorno'))
                        return
                    END
            END

        /*Valida o Nome*/
        IF EXISTS(SELECT 1 FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro) WHERE PATINDEX('%[a-z0-9-''-&-#-_- ]%', Pessoa.Registro.value('nome[1]', 'NVARCHAR(18)')) = 0 )
            BEGIN
                SET @Retorno = (select 0 as status, 'O Nome informado está incorreto' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        /*Valida a razão social, caso o tipo de documento seja CNPJ*/
        IF EXISTS(SELECT 1 FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro) WHERE PATINDEX('%[a-z0-9-''-&-#-_- ]%', Pessoa.Registro.value('razaoSocial[1]', 'NVARCHAR(150)')) = 0 AND Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') = 1)
            BEGIN
                SET @Retorno = (select 0 as status, 'A razão social está incorreta!' as mensagem FOR XML PATH('Retorno'))
                return
            END

        /*Valida os dois telefone (caso não tenha o segundo,força um valor verdadeiro)*/

        SET @TEMP_BOOL = (SELECT PATINDEX('([0-9]%[0-9]%) [0-9]%[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%[0-9]%[0-9]%', Pessoa.Registro.value('telefones[1]/Telefone[1]', 'VARCHAR(MAX)'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O telefone informado esta incorreto' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = (SELECT PATINDEX('([0-9]%[0-9]%) [0-9]%[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%[0-9]%[0-9]%', coalesce(Pessoa.Registro.value('telefones[1]/Telefone[2]', 'VARCHAR(MAX)'),'(31) 9999-9999'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O telefone secundario esta incorreto!' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        /*Valida os e-mails, caso tenha informado somente um força o segundo como correto*/

        SET @TEMP_BOOL = (SELECT PATINDEX('[a-z0-9]%@[[a-z0-9]%.[[a-z0-9]%', Pessoa.Registro.value('emails[1]/Email[1]', 'VARCHAR(MAX)'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O email informado esta incorreto' as mensagem FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = (SELECT PATINDEX('[a-z0-9]%@[[a-z0-9]%.[[a-z0-9]%', coalesce(Pessoa.Registro.value('emails[1]/Email[2]', 'VARCHAR(MAX)'),'a@com.com'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O email secundario esta incorreto' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = ( SELECT Pessoa.Registro.value('documento_cdTipo[1]', 'BIT')
                           FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        /*Valida a data de nascimento, caso o tipo de documento seja 0 (CPF)*/

        IF @TEMP_BOOL = 0
            BEGIN
                SET @TEMP_BOOL =  (SELECT isdate(CONCAT(SUBSTRING(Pessoa.Registro.value('dataNascimento[1]', 'NVARCHAR(18)'), 7, 4),'-',SUBSTRING(Pessoa.Registro.value('dataNascimento[1]', 'NVARCHAR(18)'), 1, 2),'-',SUBSTRING(Pessoa.Registro.value('dataNascimento[1]', 'NVARCHAR(18)'), 4, 2)))
                                   FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'A data de nascimento está incorreta!' as mensagem FOR XML PATH('Retorno'))
                        return
                    END

            END
        ELSE
            BEGIN
                /*Valida a data de fundação, caso o tipo de documento seja 1 (CNPJ) */
                SET @TEMP_BOOL = (SELECT IIF((isdate(CONCAT(SUBSTRING(Pessoa.Registro.value('dataFundacao[1]', 'NVARCHAR(18)'), 7, 4),'-',SUBSTRING(Pessoa.Registro.value('dataFundacao[1]', 'NVARCHAR(18)'), 1, 2),'-',SUBSTRING(Pessoa.Registro.value('dataFundacao[1]', 'NVARCHAR(18)'), 4, 2))) = 1 and Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') = 1 ),1,0)
                                  FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'A data de fundação está incorreta!' as mensagem  FOR XML PATH('Retorno'))
                        return
                    END
            END



        /*Valida Website*/
        IF EXISTS(select 1 FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro) where Pessoa.Registro.value('website[1]', 'NVARCHAR(300)') like 'http://www.%[A-Z0-9]%.%[A-Z0-9]%' or Pessoa.Registro.value('website[1]', 'NVARCHAR(300)') like 'https://www.%[A-Z0-9]%.%[A-Z0-9]%')
            BEGIN
                SET @Retorno = (select 0 as status, 'O website está incorreto!' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        INSERT INTO contatos.dbo.Pessoa (documento_cdTipo, documento_numero, nome, razaoSocial, telefones, emails, dataNascimento, dataFundacao, website)
        SELECT
            Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') as documento_cdTipo,
            Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)')  as documento_numero,
            Pessoa.Registro.value('nome[1]', 'NVARCHAR(150)')              as nome,
            Pessoa.Registro.value('razaoSocial[1]', 'NVARCHAR(150)')      as razaoSocial,
            CONCAT('<telefones>
         <Telefone principal="1">
         <numero>', Pessoa.Registro.value('telefones[1]/Telefone[1]', 'VARCHAR(MAX)'), '    </numero>
         </Telefone>
         <Telefone>
         <numero>', Pessoa.Registro.value('telefones[1]/Telefone[2]', 'VARCHAR(MAX)'), '</numero>
         </Telefone>
    </telefones>') as telefones,
            CONCAT('<emails>
         <Email principal="1">
         <endereco>', Pessoa.Registro.value('emails[1]/Email[1]', 'VARCHAR(MAX)'), '</endereco>
         </Email>
         <Email>
         <endereco>', Pessoa.Registro.value('emails[1]/Email[2]', 'VARCHAR(MAX)'), '</endereco>
         </Email>
    </emails>')            as emails,
            Pessoa.Registro.value('dataNascimento[1]', 'DATE')       as dataNascimento,
            Pessoa.Registro.value('dataFundacao[1]', 'DATE')          as dataFundacao,
            Pessoa.Registro.value('website[1]', 'NVARCHAR(300)')     as website
        FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro);

        SET @Retorno = (select 1 as status, 'Registro Inserido com Sucesso!' as mensagem,@@IDENTITY as idPessoa  FOR XML PATH('Retorno'))
    END TRY
    BEGIN CATCH
        SET @Retorno = (select 0 as status, concat('Erro: ',ERROR_MESSAGE()) as mensagem,1 as idPessoa  FOR XML PATH('Retorno'))
    END CATCH

END;
go

CREATE PROCEDURE SPA_Pessoa_UPDATE(@Campos XML, @Retorno XML OUTPUT)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @STATUS INT;
    DECLARE @MSG VARCHAR(255);
    DECLARE @BOOL BIT;
    DECLARE @TEMP_BOOL INT;

    BEGIN TRY

        /*valida se o campo idPessoa já existe */
        IF NOT EXISTS(
                SELECT 1
                FROM contatos.dbo.Pessoa
                WHERE idPessoa = (
                    SELECT Pessoa.Registro.value('idPessoa[1]', 'NVARCHAR(18)') AS idPessoa
                    FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
            )
            BEGIN
                SET @Retorno = (select 0 as status, 'O Id informado não existe!' as mensagem FOR XML PATH('Retorno'))
                return
            END

        /*valida se o campo documento_cdTipo é igual a 0 ou 1 */
        IF NOT EXISTS(SELECT 1
                      FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro)
                      WHERE Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') IN (0, 1))
            BEGIN
                SET @Retorno = (select 0 as status, 'Tipo de documento incorreto' as mensagem FOR XML PATH('Retorno'))
                return
            END

        /*valida se o campo documento_numero já existe na tabela Pessoa vinculado a outro ID */
        IF EXISTS(
                SELECT 1
                FROM contatos.dbo.Pessoa
                WHERE
                        idPessoa <> (
                        SELECT Pessoa.Registro.value('idPessoa[1]', 'NVARCHAR(18)') AS idPessoa
                        FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
                  AND
                        documento_numero = (
                        SELECT Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)') AS documento_numero
                        FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
            )
            BEGIN
                SET @Retorno = (select 0 as status, 'Este documento já previamente cadastrado' as mensagem FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = (SELECT Pessoa.Registro.value('documento_cdTipo[1]', 'BIT')
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        /*valida se o campo documento_numero é um CPF válido se [documento_cdTipo] é 0 */
        IF @TEMP_BOOL = 0
            BEGIN
                SET @TEMP_BOOL = (SELECT PATINDEX('[0-9]%[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%', Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)'))
                                  FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'O CPF informado está incorreto' as mensagem FOR XML PATH('Retorno'))
                        return
                    END
            END

        /*valida se o campo documento_numero é um CNPJ válido se [documento_cdTipo] é 1 */
        IF @BOOL = 1
            BEGIN
                SET @TEMP_BOOL = (SELECT PATINDEX('[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%.[0-9]%[0-9]%[0-9]%/[0-9]%[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%', Pessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)'))
                                  FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'O CNPJ informado está incorreto' as mensagem FOR XML PATH('Retorno'))
                        return
                    END
            END

        /*Valida o Nome*/
        IF EXISTS(SELECT 1 FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro) WHERE PATINDEX('%[a-z0-9-''-&-#-_- ]%', Pessoa.Registro.value('nome[1]', 'NVARCHAR(18)')) = 0 )
            BEGIN
                SET @Retorno = (select 0 as status, 'O Nome informado está incorreto' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        /*Valida a razão social, caso o tipo de documento seja CNPJ*/
        IF EXISTS(SELECT 1 FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro) WHERE PATINDEX('%[a-z0-9-''-&-#-_- ]%', Pessoa.Registro.value('razaoSocial[1]', 'NVARCHAR(150)')) = 0 AND Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') = 1)
            BEGIN
                SET @Retorno = (select 0 as status, 'A razão social está incorreta!' as mensagem FOR XML PATH('Retorno'))
                return
            END

        /*Valida os dois telefone (caso não tenha o segundo,força um valor verdadeiro)*/

        SET @TEMP_BOOL = (SELECT PATINDEX('([0-9]%[0-9]%) [0-9]%[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%[0-9]%[0-9]%', Pessoa.Registro.value('telefones[1]/Telefone[1]', 'VARCHAR(MAX)'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))
        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O telefone informado esta incorreto' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = (SELECT PATINDEX('([0-9]%[0-9]%) [0-9]%[0-9]%[0-9]%[0-9]%-[0-9]%[0-9]%[0-9]%[0-9]%', coalesce(Pessoa.Registro.value('telefones[1]/Telefone[2]', 'VARCHAR(MAX)'),'(31) 9999-9999'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O telefone secundario esta incorreto!' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        /*Valida os e-mails, caso tenha informado somente um força o segundo como correto*/

        SET @TEMP_BOOL = (SELECT PATINDEX('[a-z0-9]%@[[a-z0-9]%.[[a-z0-9]%', Pessoa.Registro.value('emails[1]/Email[1]', 'VARCHAR(MAX)'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O email informado esta incorreto' as mensagem FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = (SELECT PATINDEX('[a-z0-9]%@[[a-z0-9]%.[[a-z0-9]%', coalesce(Pessoa.Registro.value('emails[1]/Email[2]', 'VARCHAR(MAX)'),'a@com.com'))
                          FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        IF @TEMP_BOOL <> 1
            BEGIN
                SET @Retorno = (select 0 as status, 'O email secundario esta incorreto' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        SET @TEMP_BOOL = ( SELECT Pessoa.Registro.value('documento_cdTipo[1]', 'BIT')
                           FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

        /*Valida a data de nascimento, caso o tipo de documento seja 0 (CPF)*/

        IF @TEMP_BOOL = 0
            BEGIN
                SET @TEMP_BOOL =  (SELECT isdate(CONCAT(SUBSTRING(Pessoa.Registro.value('dataNascimento[1]', 'NVARCHAR(18)'), 7, 4),'-',SUBSTRING(Pessoa.Registro.value('dataNascimento[1]', 'NVARCHAR(18)'), 1, 2),'-',SUBSTRING(Pessoa.Registro.value('dataNascimento[1]', 'NVARCHAR(18)'), 4, 2)))
                                   FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'A data de nascimento está incorreta!' as mensagem FOR XML PATH('Retorno'))
                        return
                    END

            END
        ELSE
            BEGIN
                /*Valida a data de fundação, caso o tipo de documento seja 1 (CNPJ) */
                SET @TEMP_BOOL = (SELECT IIF((isdate(CONCAT(SUBSTRING(Pessoa.Registro.value('dataFundacao[1]', 'NVARCHAR(18)'), 7, 4),'-',SUBSTRING(Pessoa.Registro.value('dataFundacao[1]', 'NVARCHAR(18)'), 1, 2),'-',SUBSTRING(Pessoa.Registro.value('dataFundacao[1]', 'NVARCHAR(18)'), 4, 2))) = 1 and Pessoa.Registro.value('documento_cdTipo[1]', 'BIT') = 1 ),1,0)
                                  FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro))

                IF @TEMP_BOOL <> 1
                    BEGIN
                        SET @Retorno = (select 0 as status, 'A data de fundação está incorreta!' as mensagem  FOR XML PATH('Retorno'))
                        return
                    END
            END

        /*Valida Website*/
        IF EXISTS(select 1 FROM @Campos.nodes('Pessoa/Registro') Pessoa(Registro) where Pessoa.Registro.value('website[1]', 'NVARCHAR(300)') like 'http://www.%[A-Z0-9]%.%[A-Z0-9]%' or Pessoa.Registro.value('website[1]', 'NVARCHAR(300)') like 'https://www.%[A-Z0-9]%.%[A-Z0-9]%')
            BEGIN
                SET @Retorno = (select 0 as status, 'O website está incorreto!' as mensagem  FOR XML PATH('Retorno'))
                return
            END

        UPDATE contatos.dbo.Pessoa
        SET
            documento_cdTipo = xmlPessoa.Registro.value('documento_cdTipo[1]', 'BIT') ,
            documento_numero = xmlPessoa.Registro.value('documento_numero[1]', 'NVARCHAR(18)')  ,
            nome = xmlPessoa.Registro.value('nome[1]', 'NVARCHAR(150)') ,
            razaoSocial = coalesce(xmlPessoa.Registro.value('razaoSocial[1]', 'NVARCHAR(150)'),null) ,
            telefones = CONCAT('<telefones>
         <Telefone principal="1">
         <numero>', xmlPessoa.Registro.value('telefones[1]/Telefone[1]', 'VARCHAR(MAX)'), '    </numero>
         </Telefone>
         <Telefone>
         <numero>', xmlPessoa.Registro.value('telefones[1]/Telefone[2]', 'VARCHAR(MAX)'), '</numero>
         </Telefone>
    </telefones>'),
            emails = CONCAT('<emails>
         <Email principal="1">
         <endereco>', xmlPessoa.Registro.value('emails[1]/Email[1]', 'VARCHAR(MAX)'), '</endereco>
         </Email>
         <Email>
         <endereco>', xmlPessoa.Registro.value('emails[1]/Email[2]', 'VARCHAR(MAX)'), '</endereco>
         </Email>
    </emails>') ,
            dataNascimento = coalesce(xmlPessoa.Registro.value('dataNascimento[1]', 'DATE'),null) ,
            dataFundacao = coalesce(xmlPessoa.Registro.value('dataFundacao[1]', 'DATE'),null) ,
            website = coalesce(xmlPessoa.Registro.value('website[1]', 'NVARCHAR(300)'),null)
        FROM contatos.dbo.Pessoa INNER JOIN @Campos.nodes('Pessoa/Registro') xmlPessoa(Registro) ON contatos.dbo.Pessoa.idPessoa = xmlPessoa.Registro.value('idPessoa[1]', 'NVARCHAR(18)')


        SET @Retorno = (select 1 as status, 'Registro Inserido com Sucesso!' as mensagem,@@IDENTITY as idPessoa  FOR XML PATH('Retorno'))
    END TRY
    BEGIN CATCH
        SET @Retorno = (select 0 as status, concat('Erro: ',ERROR_MESSAGE()) as mensagem,1 as idPessoa  FOR XML PATH('Retorno'))
    END CATCH

END;

go



CREATE VIEW VE_Pessoa
AS
select
    idPessoa,
    case documento_cdTipo when 0 then 'F' else 'J' end as tipo,
    documento_cdTipo,
    documento_numero ,
    nome             ,
    case documento_cdTipo when 0 then null else razaoSocial end as nomeFantasia,
    razaoSocial,
    concat(telefones.value('telefones[1]/Telefone[1]', 'VARCHAR(30)'),',',telefones.value('telefones[1]/Telefone[2]', 'VARCHAR(30)'),'.') as telefones,
    telefones.value('telefones[1]/Telefone[1]', 'VARCHAR(30)') as telefonePrincipal,
    concat(emails.value('emails[1]/Email[1]', 'VARCHAR(100)'),',',emails.value('emails[1]/Email[2]', 'VARCHAR(100)'),'.') as emails,
    emails.value('emails[1]/Email[1]', 'VARCHAR(100)') as emailPrincipal,
    dataNascimento   ,
    dataFundacao     ,
    website          ,
    DTINS            ,
    DTALT            from contatos.dbo.Pessoa;

go
