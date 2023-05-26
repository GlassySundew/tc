{
	"type": "fx",
	"duration": 5,
	"cullingRadius": 3,
	"children": [
		{
			"type": "emitter",
			"name": "emitter",
			"props": {
				"emitRate": 9,
				"maxCount": 83,
				"emitOrientation": "Random",
				"instWorldAcceleration": [
					2,
					0,
					0
				]
			},
			"children": [
				{
					"type": "shader",
					"name": "Bloom",
					"source": "hrt.shader.Bloom",
					"props": {
						"flipY": 0,
						"texture": "../../../Pictures/Screenshots/Screenshot from 2023-02-18 00-16-10.png",
						"threshold": 0,
						"intensity": 0,
						"colorMatrix": null
					}
				}
			]
		}
	]
}