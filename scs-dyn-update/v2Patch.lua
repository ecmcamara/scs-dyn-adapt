local oil2 = require"oil"
return {description={name="IBye",
						interface_name="IDL:scs/demos/byeworld/IBye:1.0",
						facet_idl=oil2.readfrom("bye.idl"),
						facet_implementation=oil2.readfrom("Byev2.lua")},
					patchUpCode="",patchDownCode="",key="bye"}