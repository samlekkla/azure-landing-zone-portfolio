import { Router } from 'express';
import { trailBuddyChat } from '../services/trailBuddy.js';

const router = Router();

router.post('/', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ error: 'message is required' });

  // OpenAI model deployments blocked on Free Trial (ADR 0010) — placeholder until quota granted
  if (!process.env.AZURE_OPENAI_ENDPOINT) {
    return res.json({
      reply:  'Trail Buddy is coming soon — Azure OpenAI quota pending on this subscription.',
      source: 'placeholder'
    });
  }

  try {
    const reply = await trailBuddyChat(message);
    res.json({ reply, source: 'azure-openai-rag' });
  } catch (err) {
    console.error('Trail Buddy error:', err);
    res.status(500).json({ error: 'Trail Buddy is unavailable', detail: err.message });
  }
});

export { router as chatRouter };
