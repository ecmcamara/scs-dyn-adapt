Exemplo 1

Nota: Exemplo b�sico de adi��o de um componente primitivo e externaliza��o de uma faceta. Em seguida, � feita uma chamada a faceta externalizada.


1 - Cria��o de um componente primitivo e um composto.

lua basic_component_server.lua
lua composite_component_server.lua

2 - Execu��o do cliente 

lua client.lua  


Exemplo 2

Nota: Exemplo b�sico de uso de um conector. � criado um componente do tipo conector, um componente primitivo e um componente composto. A id�ia � externalizar
uma faceta de um subcomponente atrav�s de um conector que ser� respons�vel pela pol�tica de redirecionamento.

1 - Cria��o de um componente primitivo 

Este componente � o mesmo do Exemplo 1 que implementa a faceta com a interface IHello

2 - Cria��o de um componente do tipo conector

Este componente deve implementar a mesma faceta do subcomponente, no corpo de cada m�todo da interface devem ser implementadas as pol�ticas de comunica��o 
do componente composto e do subcomponente.

3 - Cria��o do componente composto.


4 - Como executar

lua basic_component_server.lua
lua connector_component.lua
lua composite_component_server.lua
lua testing_connector.lua