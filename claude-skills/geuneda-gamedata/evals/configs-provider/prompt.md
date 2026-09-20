---
max_turns: 6
runs: 2
allowed_tools: [Read, Glob, Grep, Skill]
tags: [api-recall]
---

우리 팀 Unity 프로젝트는 Geuneda 게임 프레임워크(`com.geuneda.gamedata`)의 설정 저장소를 쓴다.

`ItemConfig` 목록(각 항목은 `Id` 프로퍼티를 가진다)을 설정 저장소에 등록하고, ID 42 번 항목을 꺼내 쓰는 C# 스니펫을 작성해줘. 그리고 매 프레임 호출되는 루프에서 `EnemyConfig` 전체를 **힙 할당 없이** 순회하는 코드도 같이 보여줘. `using` 문까지 정확히 포함해라. 파일은 만들지 말고 코드 블록으로만 답해라.
