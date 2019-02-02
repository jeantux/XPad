unit XPAdAutoUpdateMessages;

interface

const
  NErro_Generic_FileNotFound            = 1;
  NErro_Generic_DirectoryNotFound       = 2;

  NErro_Descriptor_FileNotFound         = 11;
  NErro_Descriptor_DirectoryNotFound    = 12;
  NErro_Descriptor_FileEmpty            = 13;
  NErro_Descriptor_FileBroken           = 14;
  NErro_Descriptor_DirDownloadNotSet    = 15;
  NErro_Descriptor_DirDownloadNotFound  = 16;

  NErro_Package_FileNotFound            = 21;
  NErro_Package_BuildDirectoryNotFound  = 22;
  NErro_Package_VersionMissing          = 23;
  NErro_Package_VersionWrongFormat      = 24;
  NErro_Package_Empty                   = 25;
  NErro_Package_BuildDirectoryNotSet    = 26;
  NErro_Package_Broken                  = 27;

  NErro_CFG_ServerNotFound              = 31;
  NErro_CFG_PortMissing                 = 32;
  NErro_CFG_UserMissing                 = 33;
  NErro_CFG_PassMissing                 = 34;
  NErro_CFG_RemoteDirectoryNotFound     = 35;

  NErro_Compress_Fail                   = 41;
  NErro_Decompress_Fail                 = 51;
  NErro_Upload_Fail                     = 61;
  NErro_Download_Fail                   = 62;
  NErro_ValidateFail                    = 71;
  NErro_Publish_Fail                    = 81;
  NErro_Upgrade_Fail                    = 91;
  NErro_Delete_Fail                     = 101;
  NErro_BuildDescriptor_Fail            = 111;
  NErro_Upgrade_Cancel                  = 121;

resourcestring
  MErro_Generic_FileNotFound            = 'Arquivo não encontrado.';
  MErro_Generic_DirectoryNotFound       = 'Diretorio não encontrado.';

  MErro_Descriptor_FileNotFound         = 'Descriptor não encontrado.';
  MErro_Descriptor_DirectoryNotFound    = 'Diretório não encontrado.';
  MErro_Descriptor_DirDownloadNotSet    = 'Diretório de Download nao informado.';
  MErro_Descriptor_DirDownloadNotFound  = 'Diretporio de Download não encontrado.';

  MErro_Package_FileNotFound            = 'Pacote não encontrado.';
  MErro_Package_BuildDirectoryNotFound  = 'Diretorio de construção não encontrado.';
  MErro_Package_VersionMissing          = 'Versão do pacote não informada.';
  MErro_Package_VersionWrongFormat      = 'Versão do pacote inválida.';
  MErro_Package_Empty                   = 'Pacote vazio.';
  MErro_Package_BuildDirectoryNotSet    = 'Diretorio de construcao não informado.';
  MErro_Package_Broken                  = 'Pacote quebrado.';

  MErro_CFG_ServerNotFound              = 'Servidor não encontrado.';
  MErro_CFG_PortMissing                 = 'Porta não encontrada.';
  MErro_CFG_UserMissing                 = 'Usuário não informado.';
  MErro_CFG_PassMissing                 = 'Senha não informada.';
  MErro_CFG_RemoteDirectoryNotFound     = 'Diretório Remoto não encontrado.';

  MErro_Compress_Fail                   = 'Falha na compressão do arquivo (%s).';
  MErro_Decompress_Fail                 = 'Falha na descompressão do arquivo (%s).';
  MErro_Upload_Fail                     = 'Falha no envio do arquivo (%s).';
  MErro_Download_Fail                   = 'Falha no recebimento do arquivo (%s).';
  MErro_ValidateFail                    = 'Falha na integridade do arquivo (%s).';
  MErro_Publish_Fail                    = 'Falha na publicação do pacote (%s).';
  MErro_Upgrade_Fail                    = 'Falha na atualização do aplicativo.';
  MErro_Delete_Fail                     = 'Falha ao tentar excluir arquivo (%s)';
  MErro_BuildDescriptor_Fail            = 'Falha ao tentar carregar o descritor';
  MErro_Upgrade_Cancel                  = 'Atualização cancelada pelo usuário.';
  MErro_Search                          = 'Falha ao buscar atualização.';

  MInf_Complete                         = 'Sistema atualizado com sucesso!';
  MInf_Updated                          = 'O sistema está na ultima versão!';
  MInf_NewUpdate                        = 'Uma nova atualização foi encontrada, deseja atualizar ?';

  {Validation}
  MValid_DirNotFound                    = 'Diretorio do Executavel não informado!';
  MValid_AppNameNotFound                = 'Nome da aplicação não informada!';

implementation

end.
