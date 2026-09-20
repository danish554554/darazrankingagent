from typing import Optional

class RomanUrduPromptService:
    @staticmethod
    def generate_prompt_for_result(
        found: bool,
        keyword: str,
        page_number: Optional[int] = None,
        position: Optional[int] = None,
        is_sponsored: bool = False,
        title: Optional[str] = None
    ) -> str:
        """
        Generates natural, local Pakistani Roman Urdu feedback prompts for the testing session.
        """
        short_title = (title[:30] + "...") if title and len(title) > 30 else (title or "Aapka product")

        if found:
            rank_type = "Sponsored Ad" if is_sponsored else "Organic"
            return (
                f"Zabardast! '{short_title}' keyword '{keyword}' ke liye mil gaya hai.\n"
                f"Page {page_number}, Position #{position} ({rank_type}) par show ho raha hai.\n"
                f"Kya iska snapshot aur rank history database mein save karni hai?"
            )
        else:
            return (
                f"Aapka product pehle search results mein nahi mila keyword '{keyword}' par.\n"
                f"Kya aap deep search chalana chahte hain ya keyword change karke test karein?"
            )

    @staticmethod
    def generate_action_prompt(action: str, context: Optional[dict] = None) -> str:
        if action == "save_success":
            return "Result kamyabi se save ho gaya hai! Dashboard par rank update ho chuki hai."
        elif action == "drop_alert":
            prev = context.get("prev_rank", "-") if context else "-"
            curr = context.get("curr_rank", "-") if context else "-"
            return f"Alert: Product ki ranking #{prev} se drop hokar #{curr} par aa gayi hai. Listing optimize karne ki zaroorat hai."
        return "Task mukammal ho gaya hai."
