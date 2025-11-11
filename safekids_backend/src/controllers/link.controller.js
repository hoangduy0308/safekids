const LinkRequest = require('../models/LinkRequest');
const User = require('../models/User');

/**
 * @route   POST /api/link/request
 * @desc    Send link request (parent → child or child → parent)
 * @access  Private
 */
exports.sendRequest = async (req, res) => {
  try {
    const senderId = req.userId;
    const { receiverEmail, message } = req.body;

    if (!receiverEmail) {
      return res.status(400).json({ error: 'Email người nhận là bắt buộc' });
    }

    // Get sender and receiver
    const sender = await User.findById(senderId);
    const receiver = await User.findOne({ email: receiverEmail });

    if (!receiver) {
      return res.status(404).json({ error: 'Không tìm thấy người dùng với email này' });
    }

    if (sender._id.equals(receiver._id)) {
      return res.status(400).json({ error: 'Không thể gửi yêu cầu cho chính mình' });
    }

    // Determine request type
    let type;
    if (sender.role === 'parent' && receiver.role === 'child') {
      type = 'parent_to_child';
    } else if (sender.role === 'child' && receiver.role === 'parent') {
      type = 'child_to_parent';
    } else {
      return res.status(400).json({ 
        error: 'Chỉ có thể liên kết giữa phụ huynh và trẻ em' 
      });
    }

    // Check if already linked
    const alreadyLinked = sender.role === 'parent'
      ? sender.linkedChildren.some(id => id.equals(receiver._id))
      : sender.linkedParents.some(id => id.equals(receiver._id));

    if (alreadyLinked) {
      return res.status(400).json({ error: 'Đã liên kết với người dùng này' });
    }

    // **NEW: Check if child already has a parent (child can only join 1 family)**
    if (receiver.role === 'child' && receiver.linkedParents.length > 0) {
      return res.status(400).json({ 
        error: 'Trẻ em đã tham gia gia đình khác. Một trẻ em chỉ có thể tham gia 1 gia đình.' 
      });
    }

    // Check for existing pending request
    const existingRequest = await LinkRequest.findOne({
      sender: senderId,
      receiver: receiver._id,
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({ error: 'Đã có yêu cầu đang chờ xử lý' });
    }

    // Create link request
    const linkRequest = new LinkRequest({
      sender: senderId,
      receiver: receiver._id,
      type,
      message: message || ''
    });

    await linkRequest.save();
    await linkRequest.populate('sender', 'fullName email role');
    await linkRequest.populate('receiver', 'fullName email role');

    // Emit Socket.io event
    const socketService = req.app.get('socketService');
    if (socketService) {
      socketService.emitToUser(receiver._id.toString(), 'linkRequest', {
        requestId: linkRequest._id,
        sender: {
          id: sender._id,
          name: sender.fullName,
          email: sender.email,
          role: sender.role
        },
        message: linkRequest.message,
        type: linkRequest.type
      });
    }

    res.status(201).json({
      success: true,
      data: { request: linkRequest }
    });

  } catch (error) {
    console.error('Send link request error:', error);
    res.status(500).json({ error: 'Không thể gửi yêu cầu liên kết' });
  }
};

/**
 * @route   POST /api/link/accept/:requestId
 * @desc    Accept link request
 * @access  Private
 */
exports.acceptRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.userId;

    const linkRequest = await LinkRequest.findById(requestId)
      .populate('sender', 'fullName email role linkedChildren linkedParents')
      .populate('receiver', 'fullName email role linkedChildren linkedParents');

    if (!linkRequest) {
      return res.status(404).json({ error: 'Không tìm thấy yêu cầu liên kết' });
    }

    // Verify receiver
    if (!linkRequest.receiver._id.equals(userId)) {
      return res.status(403).json({ error: 'Bạn không có quyền chấp nhận yêu cầu này' });
    }

    if (linkRequest.status !== 'pending') {
      return res.status(400).json({ error: 'Yêu cầu đã được xử lý' });
    }

    // **NEW: Validate child can only join 1 family**
    if (linkRequest.type === 'parent_to_child') {
      // receiver is child
      if (linkRequest.receiver.linkedParents.length > 0) {
        return res.status(400).json({ 
          error: 'Trẻ em đã tham gia gia đình khác. Một trẻ em chỉ có thể tham gia 1 gia đình.' 
        });
      }
    } else if (linkRequest.type === 'child_to_parent') {
      // sender is child
      if (linkRequest.sender.linkedParents.length > 0) {
        return res.status(400).json({ 
          error: 'Trẻ em đã tham gia gia đình khác. Một trẻ em chỉ có thể tham gia 1 gia đình.' 
        });
      }
    }

    // Update link request
    linkRequest.status = 'accepted';
    await linkRequest.save();

    // Update user relationships
    const sender = linkRequest.sender;
    const receiver = linkRequest.receiver;

    if (linkRequest.type === 'parent_to_child') {
      // Add child to parent's linkedChildren
      if (!sender.linkedChildren.includes(receiver._id)) {
        sender.linkedChildren.push(receiver._id);
        await sender.save();
      }
      // Add parent to child's linkedParents
      if (!receiver.linkedParents.includes(sender._id)) {
        receiver.linkedParents.push(sender._id);
        await receiver.save();
      }
    } else {
      // child_to_parent: reverse
      if (!receiver.linkedChildren.includes(sender._id)) {
        receiver.linkedChildren.push(sender._id);
        await receiver.save();
      }
      if (!sender.linkedParents.includes(receiver._id)) {
        sender.linkedParents.push(receiver._id);
        await sender.save();
      }
    }

    // Notify sender
    const socketService = req.app.get('socketService');
    if (socketService) {
      socketService.emitToUser(sender._id.toString(), 'linkAccepted', {
        requestId: linkRequest._id,
        acceptedBy: {
          id: receiver._id,
          name: receiver.fullName,
          role: receiver.role
        }
      });
    }

    res.json({
      success: true,
      data: { request: linkRequest }
    });

  } catch (error) {
    console.error('Accept link request error:', error);
    res.status(500).json({ error: 'Không thể chấp nhận yêu cầu' });
  }
};

/**
 * @route   POST /api/link/reject/:requestId
 * @desc    Reject link request
 * @access  Private
 */
exports.rejectRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.userId;

    const linkRequest = await LinkRequest.findById(requestId)
      .populate('sender', 'fullName email role')
      .populate('receiver', 'fullName email role');

    if (!linkRequest) {
      return res.status(404).json({ error: 'Không tìm thấy yêu cầu liên kết' });
    }

    if (!linkRequest.receiver._id.equals(userId)) {
      return res.status(403).json({ error: 'Bạn không có quyền từ chối yêu cầu này' });
    }

    if (linkRequest.status !== 'pending') {
      return res.status(400).json({ error: 'Yêu cầu đã được xử lý' });
    }

    linkRequest.status = 'rejected';
    await linkRequest.save();

    // Notify sender
    const socketService = req.app.get('socketService');
    if (socketService) {
      socketService.emitToUser(linkRequest.sender._id.toString(), 'linkRejected', {
        requestId: linkRequest._id,
        rejectedBy: {
          id: linkRequest.receiver._id,
          name: linkRequest.receiver.fullName,
          role: linkRequest.receiver.role
        }
      });
    }

    res.json({
      success: true,
      data: { request: linkRequest }
    });

  } catch (error) {
    console.error('Reject link request error:', error);
    res.status(500).json({ error: 'Không thể từ chối yêu cầu' });
  }
};

/**
 * @route   GET /api/link/requests
 * @desc    Get all link requests (sent and received)
 * @access  Private
 */
exports.getRequests = async (req, res) => {
  try {
    const userId = req.userId;
    const { status } = req.query;

    const query = {
      $or: [
        { sender: userId },
        { receiver: userId }
      ]
    };

    if (status) {
      query.status = status;
    }

    const requests = await LinkRequest.find(query)
      .populate('sender', 'fullName email role')
      .populate('receiver', 'fullName email role')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { requests }
    });

  } catch (error) {
    console.error('Get link requests error:', error);
    res.status(500).json({ error: 'Không thể lấy danh sách yêu cầu' });
  }
};

/**
 * @route   DELETE /api/link/remove/:childId
 * @desc    Remove child link (parent only)
 * @access  Private
 */
exports.removeLink = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;

    const parent = await User.findById(parentId);
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xóa liên kết' });
    }

    const child = await User.findById(childId);
    if (!child || child.role !== 'child') {
      return res.status(404).json({ error: 'Không tìm thấy trẻ em' });
    }

    // Remove from parent's linkedChildren
    parent.linkedChildren = parent.linkedChildren.filter(
      id => !id.equals(childId)
    );
    await parent.save();

    // Remove from child's linkedParents
    child.linkedParents = child.linkedParents.filter(
      id => !id.equals(parentId)
    );
    await child.save();

    // Notify child
    const socketService = req.app.get('socketService');
    if (socketService) {
      socketService.emitToUser(childId, 'linkRemoved', {
        parentId: parentId,
        parentName: parent.fullName
      });
    }

    res.json({
      success: true,
      message: 'Đã xóa liên kết thành công'
    });

  } catch (error) {
    console.error('Remove link error:', error);
    res.status(500).json({ error: 'Không thể xóa liên kết' });
  }
};
