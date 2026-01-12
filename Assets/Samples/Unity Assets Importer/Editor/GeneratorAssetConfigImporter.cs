using UnityEngine;

namespace GeunedaEditor.AssetsImporter
{
	public class GeneratorAssetConfigImporter : AssetsConfigsGeneratorImporter<GameObject>
	{
		public override string TIdName => "GeneratorIds";

		public override string TScriptableObjectName => "GeneratorConfigs";
	}
}